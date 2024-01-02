const std = @import("std");

pub const Parser = struct {
    line: u64,
    col: u64,
    tokens: std.ArrayList(LexToken),
    operatedFilePath: []u8,
    operatedFileContents: std.ArrayList(u8),

    pub fn InitParser(file_name: []u8, file_contents: std.ArrayList(u8), allocator: std.mem.Allocator) Parser {
        return Parser{
            .line = 0,
            .col = 0,
            .tokens = std.ArrayList(LexToken).init(allocator),
            .operatedFilePath = file_name,
            .operatedFileContents = file_contents,
        };
    }

    pub fn DeInitParser(p: *Parser) void {
        p.tokens.deinit();
    }

    pub fn lex_tokens(p: *Parser) void {
        var buffer_reader = std.io.bufferedReader(p.operatedFileContents);
        var in_stream = buffer_reader.reader();

        var buf: [1024]u8 = undefined;

        // TODO: How do we handle EOF?
        // TODO: How do we go back a byte?
        // TODO: How to do look ahead?
        while (try in_stream.readByte(&buf)) |byte| {
            if (byte == '\n') {
                p.line += 1;
                p.col = 0;
            } else {
                p.col += 1;
            }

            // do something with line...
        }
    }
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
