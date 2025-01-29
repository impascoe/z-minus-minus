const std = @import("std");

const Keyword = union(enum) {
    _int,
    _return,
    _identifier: []u8,
};

const Literal = union(enum) {
    _int_lit: i32,
    _char_lit: u8,
};

const Punctuation = enum(u8) {
    _semicolon = ';',
    _left_curly_bracket = '{',
    _right_curly_bracket = '}',
    _left_parenthesis = '(',
    _right_parenthesis = ')',
};

const Token = union(enum) {
    _keyword: Keyword,
    _literal: Literal,
    _punctuation: Punctuation,
};

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory leak", .{});
        }
    }

    if (args.len < 2) {
        std.debug.print("Usage: {s} [filename]\n", .{args[0]});
    }

    const file = std.fs.cwd().openFile(args[1], .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };

    defer file.close();
    std.debug.print("Opened file: {s}\n", .{args[1]});

    var buffer = std.ArrayList(u8).init(allocator);
    var tokens = std.ArrayList(Token).init(allocator);
    defer buffer.deinit();
    defer tokens.deinit();

    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 2048) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |line| {
        defer allocator.free(line);
        var index: usize = 0;
        while (index < line.len) {
            const char = line[index];
            if (std.ascii.isAlphabetic(char)) {
                try buffer.append(char);
                index += 1;
                while (index < line.len and std.ascii.isAlphanumeric(line[index])) {
                    try buffer.append(line[index]);
                    index += 1;
                }
                index -= 1;
                if (std.mem.eql(u8, buffer.items, "int")) {
                    try tokens.append(Token{ ._keyword = Keyword._int });
                    buffer.clearRetainingCapacity();
                } else if (std.mem.eql(u8, buffer.items, "return")) {
                    try tokens.append(Token{ ._keyword = Keyword._return });
                    buffer.clearRetainingCapacity();
                } else {
                    var temp_index = index + 1;
                    while (temp_index < line.len and std.ascii.isWhitespace(line[temp_index])) {
                        temp_index += 1;
                    }
                    if (temp_index < line.len and line[temp_index] == @intFromEnum(Punctuation._left_parenthesis)) {
                        const identifier = try allocator.dupe(u8, buffer.items);
                        std.debug.print("Function identifier: {s}\n", .{identifier});
                        try tokens.append(Token{ ._keyword = Keyword{ ._identifier = identifier } });
                        buffer.clearRetainingCapacity();
                    } else {
                        std.debug.print("Unknown identifier: {s}\n", .{buffer.items});
                        return;
                    }
                }
            } else if (std.ascii.isDigit(char)) {
                try tokens.append(Token{ ._literal = Literal{ ._int_lit = char - '0' } });
                buffer.clearRetainingCapacity();
            } else if (std.ascii.isWhitespace(char)) {
                index += 1;
                continue;
            } else if (char == @intFromEnum(Punctuation._semicolon)) {
                try tokens.append(Token{ ._punctuation = Punctuation._semicolon });
                buffer.clearRetainingCapacity();
            } else if (char == @intFromEnum(Punctuation._left_curly_bracket)) {
                try tokens.append(Token{ ._punctuation = Punctuation._left_curly_bracket });
                buffer.clearRetainingCapacity();
            } else if (char == @intFromEnum(Punctuation._right_curly_bracket)) {
                try tokens.append(Token{ ._punctuation = Punctuation._right_curly_bracket });
                buffer.clearRetainingCapacity();
            } else if (char == @intFromEnum(Punctuation._left_parenthesis)) {
                try tokens.append(Token{ ._punctuation = Punctuation._left_parenthesis });
                buffer.clearRetainingCapacity();
            } else if (char == @intFromEnum(Punctuation._right_parenthesis)) {
                try tokens.append(Token{ ._punctuation = Punctuation._right_parenthesis });
                buffer.clearRetainingCapacity();
            } else {
                std.log.err("Unknown character: {c}", .{char});
                return;
            }
            index += 1;
        }
        buffer.clearRetainingCapacity();
    }
    // std.debug.print("{any}\n", .{tokens.items});
    // std.debug.print("{any}\n", .{tokens.items[1]});

    for (tokens.items) |token| {
        std.debug.print("{any}\n", .{token});
    }

    for (tokens.items) |token| {
        switch (token) {
            ._keyword => |keyword| {
                if (keyword == Keyword._identifier) {
                    allocator.free(keyword._identifier);
                }
            },
            else => {},
        }
    }

    // std.debug.print("{s}\n", .{tokens.items[1]._keyword._identifier});

}
