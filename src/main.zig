const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const parser = @import("parser.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    var gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);

    defer std.process.argsFree(gpa, args);

    if (args.len != 2) {
        std.debug.print("Expected file in the first argument to the program.\n", .{});
        return;
    }
    //

    var file_contents = file.LoadFileIntoMemory(args[1], gpa) catch |err| {
        var message = custom_errors.FetchCustomErrorMessage(err, custom_errors.AllCustomErrorMessages);
        std.debug.print("[-] {s}", .{message});
        return;
    };
    defer file_contents.deinit();

    var p = parser.Parser.InitParser(args[1], &file_contents, gpa);
    defer parser.Parser.DeInitParser(&p);

    parser.Parser.parse(&p) catch |err| {
        if (err == error.EndOfStream) {
            std.debug.print("[+] Successfully parsed the file.\n", .{});
        }
    };

    for (p.tokens.items) |token| {
        print_helper(&token);
    }

    std.debug.print("[?] Initialized parser with file path: {s}\n", .{p.operatedFilePath});
}

fn print_helper(token: *const parser.LexToken) void {
    if (token.token == parser.LexTokens.EOF) {
        std.debug.print("EOF reached at line {}, col: {}\n", .{ token.line.end, token.col.end });
        return;
    }
    std.debug.print("line: {}:{}, col: {}:{}, contents: {s}, tokenType: {}\n", .{ token.line.start, token.line.end, token.col.start, token.col.end, token.contents, token.token });
}
