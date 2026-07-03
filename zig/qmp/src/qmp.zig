//! Native Zig QMP (QEMU Machine Protocol) client.
//!
//! A dependency-free client for the JSON-over-socket protocol QEMU exposes
//! for machine-level control (see `docs/interop/qmp-spec.rst` in the QEMU
//! tree). No QEMU C code, no libvirt — the client links against nothing but
//! `std`, and talks to an unmodified `qemu-system-*` binary over its `-qmp`
//! control socket.
//!
//! Scope: Unix domain socket transport, the greeting + `qmp_capabilities`
//! capabilities-negotiation handshake, id-correlated command/response
//! exchange (`Client.execute`), and asynchronous server-pushed events
//! (`Client.pollEvent` / `Client.waitEvent`).
//!
//! The wire framing/classification logic (`readFrame` / `writeCommand`) is
//! transport-agnostic — it operates on `std.Io.Reader`/`std.Io.Writer`
//! directly, so it can be unit-tested against in-memory buffers without a
//! real socket or a running QEMU.

const std = @import("std");
const Io = std.Io;
const net = Io.net;

/// A server-reported command error: `{"error": {"class", "desc"}}`.
pub const CommandError = struct {
    class: []const u8,
    desc: []const u8,
};

/// A command response, matched to the `execute()` call that produced it via
/// `id`. Exactly one of `result` / `err` is non-null.
pub const Reply = struct {
    parsed: std.json.Parsed(std.json.Value),
    id: ?u64,
    result: ?std.json.Value,
    err: ?CommandError,

    pub fn deinit(self: Reply) void {
        self.parsed.deinit();
    }
};

/// An asynchronous event pushed by the server, e.g. `SHUTDOWN`, `RESET`,
/// `BLOCK_JOB_COMPLETED`.
pub const EventMsg = struct {
    parsed: std.json.Parsed(std.json.Value),
    name: []const u8,
    data: ?std.json.Value,
    /// Seconds/microseconds since the Unix epoch, or -1 if the server failed
    /// to retrieve host time (per the QMP spec), or if absent entirely.
    seconds: i64,
    microseconds: i64,

    pub fn deinit(self: EventMsg) void {
        self.parsed.deinit();
    }
};

/// The result of classifying one newline-delimited JSON message from the
/// wire: the initial server greeting, an asynchronous event, or a command
/// response (success or error).
pub const ParsedLine = union(enum) {
    greeting: std.json.Parsed(std.json.Value),
    event: EventMsg,
    reply: Reply,
};

/// Read one CRLF- (or LF-) terminated JSON message from `r` and classify it.
///
/// Transport-agnostic: `r` may be backed by a real socket or, in tests, by
/// `std.Io.Reader.fixed`.
pub fn readFrame(allocator: std.mem.Allocator, r: *Io.Reader) !ParsedLine {
    // `takeDelimiterExclusive` leaves the delimiter itself unconsumed in the
    // stream (by design, so callers can inspect it), which would make the
    // *next* read immediately see a stray leftover `\n`. Use the inclusive
    // variant, which advances past the delimiter, and strip it ourselves.
    const inclusive = try r.takeDelimiterInclusive('\n');
    const line = std.mem.trimEnd(u8, inclusive[0 .. inclusive.len - 1], "\r");

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, line, .{});
    errdefer parsed.deinit();

    const obj = switch (parsed.value) {
        .object => |o| o,
        else => return error.UnexpectedResponse,
    };

    if (obj.contains("QMP")) return .{ .greeting = parsed };

    if (obj.get("event")) |ev_val| {
        const name = switch (ev_val) {
            .string => |s| s,
            else => return error.UnexpectedResponse,
        };
        var seconds: i64 = -1;
        var microseconds: i64 = -1;
        if (obj.get("timestamp")) |ts_val| {
            if (ts_val == .object) {
                if (ts_val.object.get("seconds")) |s| {
                    if (s == .integer) seconds = s.integer;
                }
                if (ts_val.object.get("microseconds")) |m| {
                    if (m == .integer) microseconds = m.integer;
                }
            }
        }
        return .{ .event = .{
            .parsed = parsed,
            .name = name,
            .data = obj.get("data"),
            .seconds = seconds,
            .microseconds = microseconds,
        } };
    }

    const id: ?u64 = if (obj.get("id")) |v| switch (v) {
        .integer => |n| if (n >= 0) @as(u64, @intCast(n)) else return error.UnexpectedResponse,
        else => return error.UnexpectedResponse,
    } else null;

    if (obj.get("return")) |ret| {
        return .{ .reply = .{ .parsed = parsed, .id = id, .result = ret, .err = null } };
    }

    if (obj.get("error")) |err_val| {
        if (err_val != .object) return error.UnexpectedResponse;
        const class_val = err_val.object.get("class") orelse return error.UnexpectedResponse;
        const desc_val = err_val.object.get("desc") orelse return error.UnexpectedResponse;
        const class = switch (class_val) {
            .string => |s| s,
            else => return error.UnexpectedResponse,
        };
        const desc = switch (desc_val) {
            .string => |s| s,
            else => return error.UnexpectedResponse,
        };
        return .{ .reply = .{
            .parsed = parsed,
            .id = id,
            .result = null,
            .err = .{ .class = class, .desc = desc },
        } };
    }

    return error.UnexpectedResponse;
}

/// Write `{"execute": name, "arguments": args?, "id": id}` followed by a
/// newline, and flush.
///
/// Transport-agnostic: `w` may be backed by a real socket or, in tests, by
/// `std.Io.Writer.fixed`.
pub fn writeCommand(w: *Io.Writer, name: []const u8, args: ?std.json.Value, id: u64) !void {
    var stringify: std.json.Stringify = .{ .writer = w };
    try stringify.beginObject();
    try stringify.objectField("execute");
    try stringify.write(name);
    if (args) |a| {
        try stringify.objectField("arguments");
        try stringify.write(a);
    }
    try stringify.objectField("id");
    try stringify.write(id);
    try stringify.endObject();
    try w.writeByte('\n');
    try w.flush();
}

/// A connected QMP session: a Unix domain socket to a `qemu-system-*` (or
/// QEMU Guest Agent) `-qmp` control socket, past the greeting +
/// `qmp_capabilities` handshake.
///
/// Heap-allocated (via `connectUnix`) so the read/write buffers embedded in
/// it have a stable address for the lifetime of the connection.
pub const Client = struct {
    allocator: std.mem.Allocator,
    io: Io,
    stream: net.Stream,
    read_buf: [8192]u8 = undefined,
    write_buf: [4096]u8 = undefined,
    stream_reader: net.Stream.Reader = undefined,
    stream_writer: net.Stream.Writer = undefined,
    next_id: u64 = 1,
    /// Events observed while blocked in `execute()`, awaiting queued
    /// draining via `pollEvent`/`waitEvent`.
    events: std.ArrayList(EventMsg) = .empty,
    greeting: std.json.Parsed(std.json.Value) = undefined,

    /// Connect to the Unix domain socket at `path`, perform the greeting +
    /// `qmp_capabilities` handshake, and return a ready-to-use client.
    pub fn connectUnix(allocator: std.mem.Allocator, io: Io, path: []const u8) !*Client {
        const addr = try net.UnixAddress.init(path);
        const stream = try addr.connect(io);
        errdefer stream.close(io);

        const self = try allocator.create(Client);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .io = io,
            .stream = stream,
        };
        self.stream_reader = net.Stream.Reader.init(self.stream, io, &self.read_buf);
        self.stream_writer = net.Stream.Writer.init(self.stream, io, &self.write_buf);

        const first = try readFrame(allocator, &self.stream_reader.interface);
        switch (first) {
            .greeting => |g| self.greeting = g,
            .event => |e| {
                e.deinit();
                return error.UnexpectedGreeting;
            },
            .reply => |r| {
                r.deinit();
                return error.UnexpectedGreeting;
            },
        }
        errdefer self.greeting.deinit();

        var caps = try self.execute("qmp_capabilities", null);
        defer caps.deinit();
        if (caps.err != null) return error.CommandFailed;

        return self;
    }

    pub fn close(self: *Client) void {
        self.stream.close(self.io);
        self.greeting.deinit();
        for (self.events.items) |e| e.deinit();
        self.events.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    /// Send `name` (with optional `arguments`) and block until the
    /// correlated response arrives. Events observed while waiting are
    /// queued; drain them with `pollEvent`/`waitEvent`. Caller owns the
    /// returned `Reply` and must call `.deinit()`.
    pub fn execute(self: *Client, name: []const u8, args: ?std.json.Value) !Reply {
        const id = self.next_id;
        self.next_id += 1;
        try writeCommand(&self.stream_writer.interface, name, args, id);

        while (true) {
            const msg = try readFrame(self.allocator, &self.stream_reader.interface);
            switch (msg) {
                .greeting => |g| {
                    g.deinit();
                    return error.UnexpectedResponse;
                },
                .event => |e| try self.events.append(self.allocator, e),
                .reply => |r| {
                    if (r.id != null and r.id.? == id) return r;
                    // QMP without out-of-band execution replies in issue
                    // order, so this shouldn't happen; don't silently drop
                    // what looks like a real reply.
                    r.deinit();
                    return error.UnexpectedResponse;
                },
            }
        }
    }

    /// Pop the oldest queued event, if any, without blocking on the socket.
    /// Caller owns the result and must call `.deinit()`.
    pub fn pollEvent(self: *Client) ?EventMsg {
        if (self.events.items.len == 0) return null;
        return self.events.orderedRemove(0);
    }

    /// Block until the next event arrives, draining any already-queued
    /// events first. Caller owns the result and must call `.deinit()`.
    pub fn waitEvent(self: *Client) !EventMsg {
        if (self.pollEvent()) |e| return e;
        while (true) {
            const msg = try readFrame(self.allocator, &self.stream_reader.interface);
            switch (msg) {
                .greeting => |g| {
                    g.deinit();
                    return error.UnexpectedResponse;
                },
                .event => |e| return e,
                .reply => |r| {
                    // A reply with no in-flight `execute()` awaiting it.
                    r.deinit();
                    return error.UnexpectedResponse;
                },
            }
        }
    }
};

test "readFrame: classifies the server greeting" {
    var r = Io.Reader.fixed(
        "{\"QMP\": {\"version\": {\"qemu\": {\"major\": 9}}, \"capabilities\": []}}\r\n",
    );
    var msg = try readFrame(std.testing.allocator, &r);
    defer switch (msg) {
        .greeting => |g| g.deinit(),
        .event => |e| e.deinit(),
        .reply => |rep| rep.deinit(),
    };
    try std.testing.expect(msg == .greeting);
    try std.testing.expect(msg.greeting.value.object.contains("QMP"));
}

test "readFrame: classifies a successful reply and extracts id" {
    var r = Io.Reader.fixed("{\"return\": {\"status\": \"running\"}, \"id\": 7}\r\n");
    var msg = try readFrame(std.testing.allocator, &r);
    defer msg.reply.deinit();
    try std.testing.expect(msg == .reply);
    try std.testing.expectEqual(@as(?u64, 7), msg.reply.id);
    try std.testing.expect(msg.reply.err == null);
    try std.testing.expectEqualStrings(
        "running",
        msg.reply.result.?.object.get("status").?.string,
    );
}

test "readFrame: classifies an error reply" {
    var r = Io.Reader.fixed(
        "{\"error\": {\"class\": \"GenericError\", \"desc\": \"bad\"}, \"id\": 3}\r\n",
    );
    var msg = try readFrame(std.testing.allocator, &r);
    defer msg.reply.deinit();
    try std.testing.expect(msg == .reply);
    try std.testing.expectEqual(@as(?u64, 3), msg.reply.id);
    try std.testing.expect(msg.reply.result == null);
    try std.testing.expectEqualStrings("GenericError", msg.reply.err.?.class);
    try std.testing.expectEqualStrings("bad", msg.reply.err.?.desc);
}

test "readFrame: classifies an event with timestamp" {
    var r = Io.Reader.fixed(
        "{\"event\": \"SHUTDOWN\", \"data\": {\"guest\": false}, " ++
            "\"timestamp\": {\"seconds\": 1234, \"microseconds\": 5678}}\r\n",
    );
    var msg = try readFrame(std.testing.allocator, &r);
    defer msg.event.deinit();
    try std.testing.expect(msg == .event);
    try std.testing.expectEqualStrings("SHUTDOWN", msg.event.name);
    try std.testing.expectEqual(@as(i64, 1234), msg.event.seconds);
    try std.testing.expectEqual(@as(i64, 5678), msg.event.microseconds);
    try std.testing.expectEqual(false, msg.event.data.?.object.get("guest").?.bool);
}

test "readFrame: event with no data and no timestamp still parses" {
    var r = Io.Reader.fixed("{\"event\": \"STOP\"}\r\n");
    var msg = try readFrame(std.testing.allocator, &r);
    defer msg.event.deinit();
    try std.testing.expect(msg == .event);
    try std.testing.expectEqualStrings("STOP", msg.event.name);
    try std.testing.expect(msg.event.data == null);
    try std.testing.expectEqual(@as(i64, -1), msg.event.seconds);
}

test "readFrame: rejects a non-object top-level value" {
    var r = Io.Reader.fixed("[1, 2, 3]\r\n");
    try std.testing.expectError(error.UnexpectedResponse, readFrame(std.testing.allocator, &r));
}

test "readFrame: rejects an object that is neither greeting, event, nor reply" {
    var r = Io.Reader.fixed("{\"foo\": \"bar\"}\r\n");
    try std.testing.expectError(error.UnexpectedResponse, readFrame(std.testing.allocator, &r));
}

test "writeCommand: encodes execute + arguments + id" {
    var buf: [256]u8 = undefined;
    var w = Io.Writer.fixed(&buf);

    var args: std.json.ObjectMap = .empty;
    defer args.deinit(std.testing.allocator);
    try args.put(std.testing.allocator, "device", .{ .string = "virtio0" });

    try writeCommand(&w, "device_add", .{ .object = args }, 42);

    const written = buf[0..w.end];
    try std.testing.expect(std.mem.endsWith(u8, written, "\n"));

    var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, written, .{});
    defer parsed.deinit();
    const obj = parsed.value.object;
    try std.testing.expectEqualStrings("device_add", obj.get("execute").?.string);
    try std.testing.expectEqual(@as(i64, 42), obj.get("id").?.integer);
    try std.testing.expectEqualStrings(
        "virtio0",
        obj.get("arguments").?.object.get("device").?.string,
    );
}

test "writeCommand: omits arguments when null" {
    var buf: [128]u8 = undefined;
    var w = Io.Writer.fixed(&buf);
    try writeCommand(&w, "query-status", null, 1);

    const written = buf[0..w.end];
    var parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, written, .{});
    defer parsed.deinit();
    const obj = parsed.value.object;
    try std.testing.expectEqualStrings("query-status", obj.get("execute").?.string);
    try std.testing.expect(obj.get("arguments") == null);
}
