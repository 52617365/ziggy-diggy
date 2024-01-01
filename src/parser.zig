const std = @import("std");

const Parser = struct {
    line: u64,
    col: u64,
    tokens: std.ArrayList(LexToken),
    operatedFilePath: []u8,
    operatedFileContents: std.ArrayList(u8),
};

const LexToken = struct {
    line: Position,
    col: Position,
    token: Token,
};

/// This struct will hold the current position in the file.
const Position = struct {
    start: u64,
    end: u64,
};

// Tokens used in the lexical analysis phase.
const Token = enum {
    Heading,
    Paragraph,
    Bold,
    Italic,
    Link,
};

pub fn GetParser(file_name: []u8, file_contents: std.ArrayList(u8), allocator: std.mem.Allocator) Parser {
    return Parser{
        .line = 0,
        .col = 0,
        .tokens = std.ArrayList(LexToken).init(allocator),
        .operatedFilePath = file_name,
        .operatedFileContents = file_contents,
    };
}
