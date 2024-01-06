const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const parser_utils = @import("parser.zig");
const format = std.fmt;

pub fn main() !void {
    std.debug.print("\n", .{});
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    var gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);

    defer std.process.argsFree(gpa, args);

    if (args.len != 2) {
        std.debug.print("Expected file in the first argument to the program.\n", .{});
        return;
    }

    var file_contents = file.LoadFileIntoMemory(args[1], gpa) catch |err| {
        var message = custom_errors.FetchCustomErrorMessage(err, custom_errors.AllCustomErrorMessages);
        std.debug.print("[-] {s}", .{message});
        return;
    };
    defer file_contents.deinit();

    // var p = parser.Parser.InitParser(args[1], &file_contents, gpa);
    // defer parser.Parser.DeInitParser(&p);

    var parser = format.Parser{ .buf = file_contents.items };

    var tokens = std.ArrayList(parser_utils.LexToken).init(gpa);
    parser_utils.parse(&parser, &tokens) catch |err| {
        if (err == error.EndOfStream) {
            std.debug.print("[+] Successfully parsed the file.\n", .{});
        }
    };

    for (tokens.items) |token| {
        std.debug.print("Token: {any}, content as string: '{s}'\n", .{ token, token.contents });
    }

    //    parser.Parser.parse(&p) catch |err| {
    //        if (err == error.EndOfStream) {
    //            //std.debug.print("[+] Successfully parsed the file.\n", .{});
    //        }
    //    };
    //
    //    for (p.tokens.items) |token| {
    //        std.debug.print("Token: {any}\n", .{token});
    //        // print_helper(&token);
    //    }
    //std.debug.print("Tokens: {any}\n", .{p.tokens.items});
}

// fn print_helper(token: *const parser.LexToken) void {
//     if (token.token == parser.LexTokens.EOF) {
//         std.debug.print("EOF reached at line {}, col: {}\n", .{ token.line.end, token.col.end });
//         return;
//     }
//     std.debug.print("line: {}:{}, col: {}:{}, contents: {s}, tokenType: {}\n", .{ token.line.start, token.line.end, token.col.start, token.col.end, token.contents, token.token });
// }
