const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");
const file = @import("file.zig");
const parser = @import("parser.zig");

const Position = struct {
    line: u32,
    pos: u32,
};
const Parser = struct {
    pos: Position,
    operatedFilePath: []u8,
    operatedFileContents: std.ArrayList(u8),
};

const LexToken = struct {
    pos: Position,
    token: Token,
};

// Tokens for markdown
const Token = enum {
    Heading,
    Paragraph,
    Bold,
    Italic,
    Link,
};

pub fn LexTokensFromMarkdown(p: *Parser) []LexToken {
    _ = p;
    var tokens: []LexToken = undefined;

    return tokens;
}

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

    var p = parser.GetParser(args[1], file_contents, gpa);
    defer p.tokens.deinit();

    std.debug.print("[?] Initialized parser with file path: {s}\n", .{p.operatedFilePath});
}
