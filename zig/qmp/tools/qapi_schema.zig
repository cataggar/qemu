//! A small parser for QEMU's QAPI schema files (`qapi/*.json`).
//!
//! These files are *not* strict JSON: they are Python literal expressions
//! (single- or double-quoted strings, `#`-to-end-of-line comments, and a
//! sequence of top-level `{...}` dicts with no separators between them).
//! Otherwise the grammar matches JSON closely enough that we reuse
//! `std.json.Value` as the in-memory representation.
//!
//! See `docs/devel/qapi-code-gen.rst` in the QEMU tree for the authoritative
//! grammar; this parser covers the subset actually used across the 46
//! `qapi/*.json` files: objects, arrays, strings, numbers, bools, and null.

const std = @import("std");

pub const ParseError = error{
    UnexpectedChar,
    UnexpectedEof,
    UnterminatedString,
    InvalidNumber,
} || std.mem.Allocator.Error;

const Parser = struct {
    text: []const u8,
    pos: usize = 0,
    allocator: std.mem.Allocator,

    fn skipWs(p: *Parser) void {
        while (p.pos < p.text.len) {
            const c = p.text[p.pos];
            if (c == '#') {
                while (p.pos < p.text.len and p.text[p.pos] != '\n') p.pos += 1;
            } else if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
                p.pos += 1;
            } else break;
        }
    }

    fn atEnd(p: *Parser) bool {
        p.skipWs();
        return p.pos >= p.text.len;
    }

    fn peek(p: *Parser) ?u8 {
        p.skipWs();
        if (p.pos >= p.text.len) return null;
        return p.text[p.pos];
    }

    fn expectByte(p: *Parser, c: u8) !void {
        p.skipWs();
        if (p.pos >= p.text.len or p.text[p.pos] != c) return error.UnexpectedChar;
        p.pos += 1;
    }

    fn expectLiteral(p: *Parser, lit: []const u8) !void {
        if (p.pos + lit.len > p.text.len or !std.mem.eql(u8, p.text[p.pos .. p.pos + lit.len], lit)) {
            return error.UnexpectedChar;
        }
        p.pos += lit.len;
    }

    fn parseString(p: *Parser) ![]const u8 {
        p.skipWs();
        if (p.pos >= p.text.len) return error.UnexpectedEof;
        const quote = p.text[p.pos];
        if (quote != '\'' and quote != '"') return error.UnexpectedChar;
        p.pos += 1;

        var out: std.ArrayList(u8) = .empty;
        while (true) {
            if (p.pos >= p.text.len) return error.UnterminatedString;
            const c = p.text[p.pos];
            if (c == quote) {
                p.pos += 1;
                break;
            }
            if (c == '\\' and p.pos + 1 < p.text.len) {
                const esc = p.text[p.pos + 1];
                const decoded: u8 = switch (esc) {
                    'n' => '\n',
                    't' => '\t',
                    'r' => '\r',
                    '\\' => '\\',
                    '\'' => '\'',
                    '"' => '"',
                    else => esc, // permissive: unknown escapes pass the char through
                };
                try out.append(p.allocator, decoded);
                p.pos += 2;
                continue;
            }
            try out.append(p.allocator, c);
            p.pos += 1;
        }
        return out.items;
    }

    fn parseNumber(p: *Parser) !std.json.Value {
        const start = p.pos;
        if (p.pos < p.text.len and p.text[p.pos] == '-') p.pos += 1;
        var is_float = false;
        while (p.pos < p.text.len) {
            const c = p.text[p.pos];
            if (c >= '0' and c <= '9') {
                p.pos += 1;
            } else if (c == '.' or c == 'e' or c == 'E' or c == '+' or c == '-') {
                is_float = true;
                p.pos += 1;
            } else break;
        }
        const slice = p.text[start..p.pos];
        if (slice.len == 0) return error.InvalidNumber;
        if (is_float) {
            const f = std.fmt.parseFloat(f64, slice) catch return error.InvalidNumber;
            return .{ .float = f };
        }
        const n = std.fmt.parseInt(i64, slice, 10) catch return error.InvalidNumber;
        return .{ .integer = n };
    }

    fn parseValue(p: *Parser) ParseError!std.json.Value {
        p.skipWs();
        if (p.pos >= p.text.len) return error.UnexpectedEof;
        return switch (p.text[p.pos]) {
            '{' => p.parseObject(),
            '[' => p.parseArray(),
            '\'', '"' => .{ .string = try p.parseString() },
            't' => blk: {
                try p.expectLiteral("true");
                break :blk .{ .bool = true };
            },
            'f' => blk: {
                try p.expectLiteral("false");
                break :blk .{ .bool = false };
            },
            'n' => blk: {
                try p.expectLiteral("null");
                break :blk .null;
            },
            else => p.parseNumber(),
        };
    }

    fn parseObject(p: *Parser) ParseError!std.json.Value {
        try p.expectByte('{');
        var map: std.json.ObjectMap = .empty;
        p.skipWs();
        if (p.peek() == '}') {
            p.pos += 1;
            return .{ .object = map };
        }
        while (true) {
            const key = try p.parseString();
            try p.expectByte(':');
            const val = try p.parseValue();
            try map.put(p.allocator, key, val);
            p.skipWs();
            const c = p.peek() orelse return error.UnexpectedEof;
            if (c == ',') {
                p.pos += 1;
                p.skipWs();
                if (p.peek() == '}') {
                    p.pos += 1;
                    break;
                }
                continue;
            } else if (c == '}') {
                p.pos += 1;
                break;
            } else return error.UnexpectedChar;
        }
        return .{ .object = map };
    }

    fn parseArray(p: *Parser) ParseError!std.json.Value {
        try p.expectByte('[');
        var arr: std.json.Array = .init(p.allocator);
        p.skipWs();
        if (p.peek() == ']') {
            p.pos += 1;
            return .{ .array = arr };
        }
        while (true) {
            const val = try p.parseValue();
            try arr.append(val);
            p.skipWs();
            const c = p.peek() orelse return error.UnexpectedEof;
            if (c == ',') {
                p.pos += 1;
                p.skipWs();
                if (p.peek() == ']') {
                    p.pos += 1;
                    break;
                }
                continue;
            } else if (c == ']') {
                p.pos += 1;
                break;
            } else return error.UnexpectedChar;
        }
        return .{ .array = arr };
    }
};

/// Parse every top-level `{...}` expression in `text` (a single schema
/// file's contents), in order. All returned `Value`s are allocated from
/// `allocator` (pass an arena; nothing here is individually freed).
pub fn parseExpressions(allocator: std.mem.Allocator, text: []const u8) ![]std.json.Value {
    var p: Parser = .{ .text = text, .allocator = allocator };
    var exprs: std.ArrayList(std.json.Value) = .empty;
    while (!p.atEnd()) {
        const v = try p.parseValue();
        try exprs.append(allocator, v);
    }
    return exprs.items;
}

test "parseExpressions: strips comments and parses multiple top-level dicts" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const text =
        \\# -*- Mode: Python -*-
        \\## a doc comment block
        \\# @Foo: something
        \\##
        \\{ 'enum': 'Foo', 'data': [ 'a', 'b' ] }
        \\{ 'struct': 'Bar', 'data': {'x': 'int', '*y': 'str'} }
    ;
    const exprs = try parseExpressions(arena.allocator(), text);
    try std.testing.expectEqual(@as(usize, 2), exprs.len);
    try std.testing.expectEqualStrings("Foo", exprs[0].object.get("enum").?.string);
    try std.testing.expectEqualStrings("Bar", exprs[1].object.get("struct").?.string);
    try std.testing.expectEqualStrings("int", exprs[1].object.get("data").?.object.get("x").?.string);
}

test "parseExpressions: single and double quoted strings with escapes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const text =
        \\{ 'a': 'it\'s', "b": "line\nbreak" }
    ;
    const exprs = try parseExpressions(arena.allocator(), text);
    try std.testing.expectEqual(@as(usize, 1), exprs.len);
    try std.testing.expectEqualStrings("it's", exprs[0].object.get("a").?.string);
    try std.testing.expectEqualStrings("line\nbreak", exprs[0].object.get("b").?.string);
}

test "parseExpressions: nested arrays/objects, numbers, bool, null" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const text =
        \\{ 'command': 'foo', 'data': {'n': 42, 'f': 1.5, 'ok': true, 'bad': false,
        \\  'z': null, 'list': [ {'name': 'x', 'if': 'CONFIG_FOO'} ] } }
    ;
    const exprs = try parseExpressions(arena.allocator(), text);
    const data = exprs[0].object.get("data").?.object;
    try std.testing.expectEqual(@as(i64, 42), data.get("n").?.integer);
    try std.testing.expectEqual(@as(f64, 1.5), data.get("f").?.float);
    try std.testing.expectEqual(true, data.get("ok").?.bool);
    try std.testing.expectEqual(false, data.get("bad").?.bool);
    try std.testing.expectEqual(std.json.Value.null, data.get("z").?);
    try std.testing.expectEqualStrings("x", data.get("list").?.array.items[0].object.get("name").?.string);
}

test "parseExpressions: tolerates a trailing comma" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const text = "{ 'enum': 'Foo', 'data': [ 'a', 'b', ], }";
    const exprs = try parseExpressions(arena.allocator(), text);
    try std.testing.expectEqual(@as(usize, 1), exprs.len);
    try std.testing.expectEqual(@as(usize, 2), exprs[0].object.get("data").?.array.items.len);
}
