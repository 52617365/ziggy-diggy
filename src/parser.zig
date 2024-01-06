const std = @import("std");

var line: u64 = 0;
var col: u64 = 0;
var stream_index: u64 = 0;

// These two variables are used to store the start and end of the token.
var line_end: u64 = 0;
var col_end: u64 = 0;
//

pub const Parser = struct {
    line: u64,
    col: u64,
    tokens: std.ArrayList(LexToken),
    operatedFilePath: []u8,
    operatedFileContents: *std.ArrayList(u8),

    pub fn InitParser(file_name: []u8, file_contents: *std.ArrayList(u8), allocator: std.mem.Allocator) Parser {
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

    fn get_position(start: u64, end: u64) Position {
        return Position{
            .start = start,
            .end = end,
        };
    }

    fn read_next_char(p: *Parser) !u8 {
        if (stream_index + 1 >= p.operatedFileContents.items.len) {
            try p.tokens.append(LexToken{
                .line = get_position(line, line_end),
                .col = get_position(col, col_end),
                .contents = "",
                .token = LexTokens.EOF,
            });
            return error.EndOfStream;
        } else {
            stream_index += 1;
            var char = p.operatedFileContents.items[stream_index];
            col_end += 1;
            return char;
        }
    }

    fn update_line_and_column() void {
        line = line_end;
        col = col_end;
    }

    pub fn parse(p: *Parser) !void {
        defer update_line_and_column();

        var char = try read_next_char(p);

        if (char == '\n') {
            // Stuff like headings can only start at the start of a new line.
            new_line_increments();

            try p.tokens.append(LexToken{
                .line = get_position(line, line_end),
                .col = get_position(col, col_end),
                .contents = @constCast("\n"),
                .token = LexTokens.LineBreak,
            });
            try parse(p);
        } else if (char == ' ') {
            try p.tokens.append(LexToken{
                .line = get_position(line, line_end),
                .col = get_position(col, col_end),
                .contents = @constCast(" "),
                .token = LexTokens.Space,
            });
        } else if (is_unicode_identifier(char)) {
            var start_index = stream_index;

            var temp_char: u8 = try read_next_char(p);
            while (true) {
                if (!is_unicode_identifier(temp_char) and !is_number(temp_char)) {
                    break;
                }

                temp_char = try read_next_char(p);
            }

            var end_index = stream_index;

            try p.tokens.append(
                LexToken{
                    .line = get_position(line, line_end),
                    .col = get_position(col, col_end),
                    .contents = p.operatedFileContents.items[start_index - 1..end_index],
                    .token = LexTokens.Identifier,
                },
            );
        }
    }

    fn new_line_increments() void {
        line_end += 1;
        col_end = 0;
    }

    fn is_unicode_identifier(c: u8) bool {
        // Do all of the unicode characters that are allowed in identifiers.
        switch (c) {
            'a' => return true,
            'b' => return true,
            'c' => return true,
            'd' => return true,
            'e' => return true,
            'f' => return true,
            'g' => return true,
            'h' => return true,
            'i' => return true,
            'j' => return true,
            'k' => return true,
            'l' => return true,
            'm' => return true,
            'n' => return true,
            'o' => return true,
            'p' => return true,
            'q' => return true,
            'r' => return true,
            's' => return true,
            't' => return true,
            'u' => return true,
            'v' => return true,
            'w' => return true,
            'x' => return true,
            'y' => return true,
            'z' => return true,
            'ö' => return true,
            'ä' => return true,
            'å' => return true,

            'A' => return true,
            'B' => return true,
            'C' => return true,
            'D' => return true,
            'E' => return true,
            'F' => return true,
            'G' => return true,
            'H' => return true,
            'I' => return true,
            'J' => return true,
            'K' => return true,
            'L' => return true,
            'M' => return true,
            'N' => return true,
            'O' => return true,
            'P' => return true,
            'Q' => return true,
            'R' => return true,
            'S' => return true,
            'T' => return true,
            'U' => return true,
            'V' => return true,
            'W' => return true,
            'X' => return true,
            'Y' => return true,
            'Z' => return true,
            'Ö' => return true,
            'Ä' => return true,
            'Å' => return true,
            else => {
                return false;
            },
        }
    }

    fn is_number(c: u8) bool {
        return c >= '0' and c <= '9';
    }
};

const LexToken = struct {
    line: Position,
    col: Position,
    contents: []u8,
    token: LexTokens,
};

/// This struct will hold the current position in the file.
const Position = struct {
    start: u64,
    end: u64,
};

// Tokens used in the lexical analysis phase.
const LexTokens = enum {
    Heading,
    Identifier,
    Paragraph,
    Bold,
    Italic,
    Link,
    EOF,
    LineBreak,
    Space,
};
