const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const parser_utils = @import("lex.zig");
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

    var parser = format.Parser{ .buf = file_contents.items };

    var tokens = std.ArrayList(parser_utils.LexToken).init(gpa);
    defer tokens.deinit();

    parser_utils.get_tokens(&parser, &tokens) catch |err| {
        if (err == error.EndOfStream) {
            std.debug.print("[+] Successfully parsed the file.\n", .{});
        }
    };

    for (tokens.items) |token| {
        std.debug.print("Token: {any}, content as string: '{s}'\n", .{ token, token.contents });
    }

    // TODO: Do a second iteration on the tokens to form a better understanding of the structure.
    // For example, headers, italic, bold, etc texts.
}
