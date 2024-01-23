const std = @import("std");
const testing = std.testing;
// const build_option = @import("config");

var line: u64 = 0;
var col: u64 = 0; // This variable is only used when the debug_msg flag is set to true when compiling the program. var parse_call_counter: u64 = 0; // @Performance: we could instead of having only buf in this struct, have a text_buf that contains the raw data in u8
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
    var start_line = line;
    var start_col = col;

    var char = parser.char();
    if (char == null) {
        try capture_token(tokens, @constCast(""), TokenTypes.EOF, start_line, start_col);
        return error.EndOfStream;
    }

    if (char.? == '\n') {
        line += 1;
        col = 0;

        var start_pos = parser.pos;
        {
            if (parser.peek(1) == '#') {
                var heading_ahead = false;
                var header_amount: u64 = 1;
                var peek_amount: u64 = 1;
                while (parser.peek(peek_amount) == '#') : (peek_amount += 1) {
                    header_amount += 1;
                }

                if (header_amount < 7 and parser.peek(peek_amount + 1) == ' ') {
                    heading_ahead = true;
                }

                if (heading_ahead) {
                    // TODO: why are we never getting into this branch?
                    parser.pos += peek_amount;

                    // @Copypasta
                    var text_start_pos = parser.pos;

                    while (true) {
                        if (parser.pos >= parser.buf.len) break;

                        if (!is_unicode_identifier(parser.buf[parser.pos]) and !is_number(parser.buf[parser.pos]) and !is_symbol(parser.buf[parser.pos])) {
                            break;
                        }

                        parser.pos += 1;
                        col += 1;
                    }

                    var end_pos = parser.pos;
                    //

                    std.debug.print("Found heading with {} hashtags. Contents of heading: {s}", .{ header_amount, parser.buf[text_start_pos..end_pos] });
                    try get_tokens(parser, tokens);
                } else {
                    // @Copypasta
                    while (true) {
                        if (parser.pos >= parser.buf.len) break;

                        if (!is_unicode_identifier(parser.buf[parser.pos]) and !is_number(parser.buf[parser.pos]) and !is_symbol(parser.buf[parser.pos])) {
                            break;
                        }

                        parser.pos += 1;
                        col += 1;
                    }

                    var end_pos = parser.pos;
                    //
                    std.debug.print("Found text with {} hashtags. Contents of text: {s}\n", .{ header_amount, parser.buf[start_pos..end_pos] });
                    try capture_token(tokens, @constCast(parser.buf[start_pos..end_pos]), TokenTypes.Identifier, start_line, start_col);
                    try get_tokens(parser, tokens);
                }
                // std.debug.print("Found hashtags, got {} hashtags. heading_ahead = {}\n", .{ header_amount, heading_ahead });
            }
        }

        try capture_token(tokens, @constCast("\\n"), TokenTypes.LineBreak, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == ' ') {
        try capture_token(tokens, @constCast(" "), TokenTypes.Space, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '#') {
        try capture_token(tokens, @constCast("#"), TokenTypes.Hashtag, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '*') {
        try capture_token(tokens, @constCast("*"), TokenTypes.Asterisk, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '[') {
        try capture_token(tokens, @constCast("["), TokenTypes.BracketOpen, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == ']') {
        try capture_token(tokens, @constCast("]"), TokenTypes.BracketClose, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '`') {
        try capture_token(tokens, @constCast("`"), TokenTypes.Backtick, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '<') {
        try capture_token(tokens, @constCast("<"), TokenTypes.SmallerThan, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '>') {
        try capture_token(tokens, @constCast(">"), TokenTypes.LargerThan, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (char.? == '|') {
        try capture_token(tokens, @constCast("|"), TokenTypes.Pipe, start_line, start_col);
        try get_tokens(parser, tokens);
    } else if (is_unicode_identifier(char.?) or is_number(char.?)) {
        var start_pos = parser.pos;

        // @Copypasta
        while (true) {
            if (parser.pos >= parser.buf.len) break;

            if (!is_unicode_identifier(parser.buf[parser.pos]) and !is_number(parser.buf[parser.pos])) {
                break;
            }

            parser.pos += 1;
            col += 1;
        }

        var end_pos = parser.pos;

        try capture_token(tokens, @constCast(parser.buf[start_pos - 1 .. end_pos]), TokenTypes.Identifier, start_line, start_col);
        try get_tokens(parser, tokens);
    }
}

fn capture_token(tokens: *std.ArrayList(LowLevelLexToken), contents: []u8, tokenType: TokenTypes, start_line: u64, start_col: u64) !void {
    try tokens.append(LowLevelLexToken{
        .start_line = start_line,
        .end_line = line,
        .start_col = start_col,
        .end_col = col,
        .contents = contents,
        .token = tokenType,
    });
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
        ' ' => return true,
        else => {
            return false;
        },
    }
}

fn is_symbol(c: u8) bool {
    return switch (c) {
        // Common symbols and special characters
        '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '_', '`', '{', '|', '}', '~' => true,
        // Default case if none of the above
        else => false,
    };
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
    token: TokenTypes,
};

// Tokens used in the lexical analysis phase.
pub const TokenTypes = enum {
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

test "test build low level tokens" {
    var testing_allocator = std.testing.allocator;

    var file_contents = std.ArrayList(u8).init(testing_allocator);
    defer file_contents.deinit();

    try file_contents.appendSlice(@constCast("Hello_world_identifier_token"));

    const LLparser = get_parser_type(u8);
    var parser = LLparser{ .buf = file_contents.items };

    var tokens = std.ArrayList(LowLevelLexToken).init(testing_allocator);
    defer tokens.deinit();

    get_tokens(&parser, &tokens) catch |err| {
        try testing.expect(err == error.EndOfStream);
        std.debug.print("[+] Successfully parsed the file.\n", .{});
    };

    try testing.expect(tokens.items[0].token == TokenTypes.Identifier);
}
