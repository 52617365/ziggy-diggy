const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const parser = @import("parser.zig").Parser;

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

    var p = parser.InitParser(args[1], &file_contents, gpa);
    defer parser.DeInitParser(&p);

    try parser.parse(&p);

    for (p.tokens.items) |token| {
        std.debug.print("{}\n", .{token});
    }

    std.debug.print("[?] Initialized parser with file path: {s}\n", .{p.operatedFilePath});
}
