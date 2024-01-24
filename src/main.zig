const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const fmt = @import("std").fmt;
const parser_utils = @import("parser.zig");

pub fn main() !void {
    std.debug.print("\n", .{});
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    var gpa = general_purpose_allocator.allocator();

    var args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var file_name = std.ArrayList(u8).init(gpa);
    defer file_name.deinit();

    if (args.len != 2) {
        std.debug.print("Expected file in the first argument to the program. Setting it to test.md\n\n", .{});
        // std.debug.print("For testing purposes, we are going to fill the args ourselves.\n", .{});
        try file_name.appendSlice("test.md");
    } else {
        try file_name.appendSlice(args[1]);
    }

    var file_contents = file.LoadFileIntoMemory(file_name.items, gpa) catch |err| {
        // var message = custom_errors.FetchCustomErrorMessage(err, custom_errors.AllCustomErrorMessages);
        std.debug.print("[-] {any}", .{err});
        return;
    };
    defer file_contents.deinit();

    const LLparser = parser_utils.get_parser_type(u8);
    var parser = LLparser{ .buf = file_contents.items };

    var tokens = std.ArrayList(parser_utils.LowLevelLexToken).init(gpa);
    defer tokens.deinit();

    parser_utils.get_tokens(&parser, &tokens) catch |err| {
        if (err == error.EndOfStream) {
            std.debug.print("[+] Successfully parsed the file.\n", .{});
        }
    };

    std.debug.print("\n[+] Low level tokens:\n", .{});
    for (tokens.items) |token| {
        std.debug.print("Token: {any}, content as string: '{s}'\n", .{ token, token.contents });
    }
}
