const std = @import("std");
const build_option = @import("config");

var line: u64 = 0;
var col: u64 = 0;

// This variable is only used when the debug_msg flag is set to true when compiling the program.
var parse_call_counter: u64 = 0;

// @Performance: we could instead of having only buf in this struct, have a text_buf that contains the raw data in u8
// It would allow us to be able to get slices from the original text_buf instead of allocating dynamic arrays.
// to gather the individual strings from many strings to one array.
pub fn get_parser_type(comptime t: type) type {
    return struct {
        buf: []const t,
        pos: usize = 0,

        // Returns a substring of the input starting from the current position
        // and ending where `ch` is found or until the end if not found
        pub fn until(self: *@This(), ch: t) []const t {
            const start = self.pos;

            if (start >= self.buf.len)
                return &[_]u8{};

            while (self.pos < self.buf.len) : (self.pos += 1) {
                if (self.buf[self.pos] == ch) break;
            }
            return self.buf[start..self.pos];
        }

        // Returns one character, if available
        pub fn char(self: *@This()) ?t {
            if (self.pos < self.buf.len) {
                const ch = self.buf[self.pos];
                self.pos += 1;
                col += 1;
                return ch;
            }
            return null;
        }

        pub fn maybe(self: *@This(), val: t) bool {
            if (self.pos < self.buf.len and self.buf[self.pos] == val) {
                self.pos += 1;
                return true;
            }
            return false;
        }

        // Returns the n-th next character or null if that's past the end
        pub fn peek(self: *@This(), n: usize) ?t {
            return if (self.pos + n < self.buf.len) self.buf[self.pos + n] else null;
        }
    };
}

const llParser = get_parser_type(u8);
pub const llTokenParser = get_parser_type(LowLevelLexToken);

pub fn get_tokens(parser: *llParser, tokens: *std.ArrayList(LowLevelLexToken)) !void {
    if (build_option.debug_msg) {
        parse_call_counter += 1;
    }
    var start_line = line;
    var start_col = col;

    var char = parser.char();
    if (char == null) {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = "",
            .token = LowLevelTokens.EOF,
        });
        return error.EndOfStream;
    }

    if (char.? == '\n') {
        line += 1;
        col = 0;
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("\\n"),
            .token = LowLevelTokens.LineBreak,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == ' ') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast(" "),
            .token = LowLevelTokens.Space,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '#') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("#"),
            .token = LowLevelTokens.Hashtag,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '*') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("*"),
            .token = LowLevelTokens.Asterisk,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '[') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("["),
            .token = LowLevelTokens.BracketOpen,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == ']') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("]"),
            .token = LowLevelTokens.BracketClose,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '`') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("`"),
            .token = LowLevelTokens.Backtick,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '<') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("<"),
            .token = LowLevelTokens.SmallerThan,
        });
        try get_tokens(parser, tokens);
    } else if (char.? == '>') {
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast(">"),
            .token = LowLevelTokens.LargerThan,
        });
        if (build_option.debug_msg) {
            std.debug.print("parser pos: {}\n", .{parser.pos});
        }
        try get_tokens(parser, tokens);
    } else if (char.? == '|') {
        //std.debug.print("peekaboo got |", .{});
        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast("|"),
            .token = LowLevelTokens.Pipe,
        });
        try get_tokens(parser, tokens);
    } else if (is_unicode_identifier(char.?) or is_number(char.?)) {
        var start_pos = parser.pos;

        while (true) {
            if (parser.pos >= parser.buf.len) break;

            if (!is_unicode_identifier(parser.buf[parser.pos]) and !is_number(parser.buf[parser.pos])) {
                break;
            }

            parser.pos += 1;
            col += 1;
        }

        var end_pos = parser.pos;

        try tokens.append(LowLevelLexToken{
            .start_line = start_line,
            .end_line = line,
            .start_col = start_col,
            .end_col = col,
            .contents = @constCast(parser.buf[start_pos - 1 .. end_pos]),
            .token = LowLevelTokens.Identifier,
        });
        try get_tokens(parser, tokens);
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

pub const LowLevelLexToken = struct {
    start_line: u64,
    start_col: u64,
    end_line: u64,
    end_col: u64,
    contents: []u8,
    token: LowLevelTokens,
};

// Tokens used in the lexical analysis phase.
pub const LowLevelTokens = enum {
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
    Pipe, // |
};

pub const HighLevelTokens = enum {
    Heading1,
    Heading2,
    Heading3,
    Heading4,
    Heading5,
    Heading6,
    Text,
    Emphasis,
    List,
    Image,
    Code, // #
    Table, // *
    Blockquote, // [
    EOF,
};

pub const HighLevelLexToken = struct {
    // start_line: u64,
    // start_col: u64,
    col: u64,
    line: u64,
    contents: []u8,
    token: HighLevelTokens,
    // ll_token: []LowLevelTokens,
};

/// traverse_and_form_high_level_tokens() is used to iterate the tokens and form a new kind of token that represents a higher level view of markdown.
/// This is done because it's easier to generate a higher representation when E.g. identifiers are one token instead of 10 different
/// individual characters.
/// TODO: in the caller, catch the error.EndOfStream and in that case append EOF to the end of the high tokens
/// do this because we don't want to handle it 100 times in this function.
pub fn traverse_and_form_high_level_tokens(highTokens: *std.ArrayList(HighLevelLexToken), low_level_tokens_parser: *llTokenParser, gpa: std.mem.Allocator) !void {
    var token = low_level_tokens_parser.char();

    if (token.?.token == LowLevelTokens.EOF) {
        try highTokens.append(HighLevelLexToken{
            // .start_col = col - 1,
            // .start_line = line,
            .col = col,
            .line = line,
            .contents = "",
            .token = HighLevelTokens.EOF,
        });
        return error.EndOfStream;
    }
    if (token.?.token == LowLevelTokens.LineBreak) {
        var next_token = low_level_tokens_parser.char();
        if (next_token.?.token == LowLevelTokens.Hashtag) {
            var header_count: u64 = 0;

            while (low_level_tokens_parser.pos > low_level_tokens_parser.buf.len) : (low_level_tokens_parser.pos += 1) {
                if (low_level_tokens_parser.buf[low_level_tokens_parser.pos].token != LowLevelTokens.Hashtag) {
                    break;
                } else {
                    header_count += 1;
                }
            }
            if (header_count > 6) { // Markdown can't have headings that are larger than 6 hashtags.
                var combined_texts = std.ArrayList(u8).init(gpa);
                // In this block it's text, so make sure that you go till the end of text.
                while (low_level_tokens_parser.pos < low_level_tokens_parser.buf.len) : (low_level_tokens_parser.pos += 1) {
                    if (low_level_tokens_parser.buf[low_level_tokens_parser.pos].token != LowLevelTokens.Identifier) {
                        break;
                    } else {
                        try combined_texts.appendSlice(low_level_tokens_parser.buf[low_level_tokens_parser.pos].contents);
                    }
                }
                try highTokens.append(HighLevelLexToken{
                    .line = line,
                    .col = col,
                    .contents = try combined_texts.toOwnedSlice(),
                    .token = HighLevelTokens.Text,
                });
                try traverse_and_form_high_level_tokens(highTokens, low_level_tokens_parser, gpa);
            } else {
                if (low_level_tokens_parser.peek(1).?.token == LowLevelTokens.Space) {
                    // Found a heading.

                    var type_of_heading: HighLevelTokens = undefined;
                    if (header_count == 1) {
                        type_of_heading = HighLevelTokens.Heading1;
                    } else if (header_count == 2) {
                        type_of_heading = HighLevelTokens.Heading2;
                    } else if (header_count == 3) {
                        type_of_heading = HighLevelTokens.Heading3;
                    } else if (header_count == 4) {
                        type_of_heading = HighLevelTokens.Heading4;
                    } else if (header_count == 5) {
                        type_of_heading = HighLevelTokens.Heading5;
                    } else if (header_count == 6) {
                        type_of_heading = HighLevelTokens.Heading6;
                    }

                    // Traversing to the actual heading text.
                    low_level_tokens_parser.pos += 2;

                    var combined_texts = std.ArrayList(u8).init(gpa);

                    while (low_level_tokens_parser.pos < low_level_tokens_parser.buf.len) : (low_level_tokens_parser.pos += 1) {
                        if (low_level_tokens_parser.buf[low_level_tokens_parser.pos].token == LowLevelTokens.LineBreak) {
                            break;
                        } else if (low_level_tokens_parser.buf[low_level_tokens_parser.pos].token == LowLevelTokens.Identifier or low_level_tokens_parser.buf[low_level_tokens_parser.pos].token == LowLevelTokens.Space) {
                            try combined_texts.appendSlice(low_level_tokens_parser.buf[low_level_tokens_parser.pos].contents);
                        }
                    }

                    try highTokens.append(HighLevelLexToken{ .line = line, .col = col, .contents = try combined_texts.toOwnedSlice(), .token = type_of_heading });
                } else {
                    // TODO: If it's not a space, it's text.
                }
            }
            // TODO: handle all the other possibilities that can happen only after new lines.
            // } else if () {

        } else {}
    } else if (token.?.token == LowLevelTokens.Identifier) {
        // TODO: collect all identifiers after this to one Text high level token.

        var combined_texts = std.ArrayList(u8).init(gpa);

        try combined_texts.appendSlice(token.?.contents);

        while (true) {
            var iterated_token = low_level_tokens_parser.char();

            if (iterated_token.?.token == LowLevelTokens.EOF) {
                low_level_tokens_parser.pos -= 1; // Going back one in position so that the next iteration will handle EOF.
                var end_col_of_identifier = iterated_token.?.end_col;
                var end_line_of_identifier = iterated_token.?.end_line;
                try highTokens.append(HighLevelLexToken{
                    .col = end_col_of_identifier,
                    .line = end_line_of_identifier,
                    .contents = try combined_texts.toOwnedSlice(),
                    .token = HighLevelTokens.Text,
                });
            }

            if (iterated_token.?.token == LowLevelTokens.Identifier or iterated_token.?.token == LowLevelTokens.Space) {
                try combined_texts.appendSlice(iterated_token.?.contents);
            } else {
                break;
            }
        }
        var current_location = low_level_tokens_parser.peek(0);
        var end_col_of_identifier = current_location.?.end_col;
        var end_line_of_identifier = current_location.?.end_line;
        try highTokens.append(HighLevelLexToken{
            .col = end_col_of_identifier,
            .line = end_line_of_identifier,
            .contents = try combined_texts.toOwnedSlice(),
            .token = HighLevelTokens.Text,
        });
        try traverse_and_form_high_level_tokens(highTokens, low_level_tokens_parser, gpa);
    }
}
