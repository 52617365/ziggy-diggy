const std = @import("std");
const build_option = @import("config");
const format = std.fmt;

var line: u64 = 0;
var col: u64 = 0;

// This variable is only used when the debug_msg flag is set to true when compiling the program.
var parse_call_counter: u64 = 0;

pub fn parse(parser: *format.Parser, tokens: *std.ArrayList(LexToken)) !void {
    if (build_option.debug_msg) {
        parse_call_counter += 1;
    }

    var char = parser.char();
    if (char == null) {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = "",
            .token = LexTokens.EOF,
        });
        return error.EndOfStream;
    }

    if (char.? == '\n') {
        // A lot of stuff can only happen after a new line in markdown so this will hold a lot of peaking shit.
        line += 1;
        col = 0;
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("\n"),
            .token = LexTokens.LineBreak,
        });
        try parse(parser, tokens);
    } else if (char.? == ' ') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast(" "),
            .token = LexTokens.Space,
        });
        try parse(parser, tokens);
    } else if (char.? == '#') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("#"),
            .token = LexTokens.Hashtag,
        });
        try parse(parser, tokens);
    } else if (char.? == '*') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("*"),
            .token = LexTokens.Asterisk,
        });
        try parse(parser, tokens);
    } else if (char.? == '[') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("["),
            .token = LexTokens.BracketOpen,
        });
        try parse(parser, tokens);
    } else if (char.? == ']') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("]"),
            .token = LexTokens.BracketClose,
        });
        try parse(parser, tokens);
    } else if (char.? == '`') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("`"),
            .token = LexTokens.Backtick,
        });
        try parse(parser, tokens);
    } else if (char.? == '<') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast("<"),
            .token = LexTokens.SmallerThan,
        });
        try parse(parser, tokens);
    } else if (char.? == '>') {
        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast(">"),
            .token = LexTokens.LargerThan,
        });
        try parse(parser, tokens);
    } else if (is_unicode_identifier(char.?) or is_number(char.?)) {
        var start_pos = parser.pos;

        while (true) {
            if (parser.pos >= parser.buf.len) break;

            if (!is_unicode_identifier(parser.buf[parser.pos]) and !is_number(parser.buf[parser.pos])) {
                break;
            }

            parser.pos += 1;
        }

        var end_pos = parser.pos;

        if (build_option.debug_msg) {
            std.debug.print("PEEKABOOO! {u}\n", .{parser.buf[end_pos - 1]});
        }

        try tokens.append(LexToken{
            .line = line,
            .col = col,
            .contents = @constCast(parser.buf[start_pos - 1 .. end_pos]),
            .token = LexTokens.Identifier,
        });
        try parse(parser, tokens);
    }
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

fn is_unicode_identifier_or_number(c: ?u8) bool {
    if (c == null) return false;

    return is_unicode_identifier(c.?) and is_number(c.?);
}
pub const LexToken = struct {
    line: u64,
    col: u64,
    contents: []u8,
    token: LexTokens,
};

// Tokens used in the lexical analysis phase.
pub const LexTokens = enum {
    Identifier,
    EOF,
    LineBreak,
    Space,
    Hashtag, // #
    Asterisk, // *
    BracketOpen, // [
    BracketClose, // ]
    Backtick, // `
    SmallerThan, // <
    LargerThan, // >
};
