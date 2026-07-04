//! A minimal, single-connection-at-a-time native Zig NBD server, serving a
//! single raw-file-backed export. Complements the `Client` in `nbd.zig` --
//! primarily useful for testing that `Client` against a from-scratch server
//! implementation, and for manual interop testing against real NBD clients
//! (e.g. `qemu-img info nbd+unix://...` or another `nbd` CLI instance).
//!
//! Scope: fixed newstyle handshake supporting `NBD_OPT_EXPORT_NAME` and
//! `NBD_OPT_GO` (any other option is rejected with `NBD_REP_ERR_UNSUP`,
//! except `NBD_OPT_ABORT` which is acknowledged and ends the session) for
//! exactly one, fixed export name, `NBD_OPT_STRUCTURED_REPLY`, and the
//! `READ`/`WRITE`/`FLUSH`/`TRIM`/`WRITE_ZEROES`/`DISC` transmission
//! commands.
//!
//! This is *not* hardened against malicious input the way a production NBD
//! server would need to be (e.g. request lengths are trusted enough to
//! drive a single allocation) -- it exists for interop testing, not for
//! exposing to untrusted clients.

const std = @import("std");
const Io = std.Io;
const net = Io.net;
const nbd = @import("nbd.zig");

/// A raw (flat) file backend: NBD offsets map 1:1 onto file offsets.
pub const RawFile = struct {
    file: Io.File,
    io: Io,
    size: u64,

    /// Open an existing raw file at `path` (relative to `dir`) for reading
    /// and writing.
    pub fn open(io: Io, dir: Io.Dir, path: []const u8) !RawFile {
        const file = try dir.openFile(io, path, .{ .mode = .read_write });
        errdefer file.close(io);
        const st = try file.stat(io);
        return .{ .file = file, .io = io, .size = st.size };
    }

    pub fn close(self: *RawFile) void {
        self.file.close(self.io);
    }

    pub fn read(self: *RawFile, offset: u64, buf: []u8) !void {
        const got = try self.file.readPositionalAll(self.io, buf, offset);
        if (got != buf.len) return error.Truncated;
    }

    pub fn write(self: *RawFile, offset: u64, data: []const u8) !void {
        try self.file.writePositionalAll(self.io, data, offset);
    }

    pub fn flush(self: *RawFile) !void {
        try self.file.sync(self.io);
    }
};

/// NBD ("Linux errno") value reported to clients for any internal
/// read/write/flush failure. Good enough for a test/interop server; a real
/// server would map specific `std.posix` errors to the closest NBD errno.
const nbd_eio: u32 = 5;

/// The transmission flags this server advertises for every export: flush,
/// trim, and write-zeroes are all backed directly by `RawFile` methods (trim
/// is accepted but is a no-op, which is spec-legal -- servers MAY ignore it).
const transmission_flags: u16 = nbd.flag_has_flags | nbd.flag_send_flush | nbd.flag_send_trim | nbd.flag_send_write_zeroes;

/// Serve `backing` on an already-accepted connection `stream`, for exactly
/// one export named `export_name`. Blocks until the client disconnects
/// (`NBD_CMD_DISC`, a hard socket close, or a fatal protocol error).
/// `allocator` is used for per-request READ/WRITE buffers.
pub fn serveOne(allocator: std.mem.Allocator, io: Io, stream: net.Stream, export_name: []const u8, backing: *RawFile) !void {
    var read_buf: [65536]u8 = undefined;
    var write_buf: [65536]u8 = undefined;
    var stream_reader = net.Stream.Reader.init(stream, io, &read_buf);
    var stream_writer = net.Stream.Writer.init(stream, io, &write_buf);
    const r = &stream_reader.interface;
    const w = &stream_writer.interface;

    try w.writeInt(u64, nbd.init_magic, .big);
    try w.writeInt(u64, nbd.opts_magic, .big);
    try w.writeInt(u16, nbd.handshake_flag_fixed_newstyle | nbd.handshake_flag_no_zeroes, .big);
    try w.flush();

    const client_flags = try r.takeInt(u32, .big);
    const client_no_zeroes = client_flags & nbd.client_flag_no_zeroes != 0;

    var structured_replies = false;
    const entered_transmission = try negotiate(r, w, export_name, backing.size, client_no_zeroes, &structured_replies);
    if (!entered_transmission) return;

    while (true) {
        const req = nbd.readRequestHeader(r) catch |err| switch (err) {
            error.EndOfStream => return,
            else => return err,
        };
        try handleRequest(allocator, r, w, req, backing, structured_replies);
        if (req.type == nbd.cmd_disc) return;
    }
}

/// Option-haggling loop. Returns whether the session should proceed to the
/// transmission phase (`true`), or has already ended (`false`, e.g. after
/// `NBD_OPT_ABORT`).
fn negotiate(
    r: *Io.Reader,
    w: *Io.Writer,
    export_name: []const u8,
    export_size: u64,
    client_no_zeroes: bool,
    structured_replies: *bool,
) !bool {
    while (true) {
        const magic = try r.takeInt(u64, .big);
        if (magic != nbd.opts_magic) return nbd.Error.UnexpectedMagic;
        const option = try r.takeInt(u32, .big);
        const length = try r.takeInt(u32, .big);

        switch (option) {
            nbd.opt_export_name => {
                const name = try r.take(length);
                if (!std.mem.eql(u8, name, export_name)) return error.UnknownExport;
                try w.writeInt(u64, export_size, .big);
                try w.writeInt(u16, transmission_flags, .big);
                if (!client_no_zeroes) try w.splatByteAll(0, 124);
                try w.flush();
                return true;
            },
            nbd.opt_go, nbd.opt_info => {
                if (length < 6) return nbd.Error.UnexpectedReply;
                const name_len = try r.takeInt(u32, .big);
                const name = try r.take(name_len);
                const matches = std.mem.eql(u8, name, export_name);
                const n_info = try r.takeInt(u16, .big);
                if (n_info > 0) try r.discardAll(@as(usize, n_info) * 2);

                if (!matches) {
                    try writeOptionReplyEmpty(w, option, nbd.rep_err_unknown);
                    continue;
                }
                var info_payload: [12]u8 = undefined;
                std.mem.writeInt(u16, info_payload[0..2], nbd.info_export, .big);
                std.mem.writeInt(u64, info_payload[2..10], export_size, .big);
                std.mem.writeInt(u16, info_payload[10..12], transmission_flags, .big);
                try writeOptionReply(w, option, nbd.rep_info, &info_payload);
                try writeOptionReplyEmpty(w, option, nbd.rep_ack);
                if (option == nbd.opt_go) return true;
            },
            nbd.opt_structured_reply => {
                if (length > 0) try r.discardAll(length);
                structured_replies.* = true;
                try writeOptionReplyEmpty(w, option, nbd.rep_ack);
            },
            nbd.opt_abort => {
                if (length > 0) try r.discardAll(length);
                try writeOptionReplyEmpty(w, option, nbd.rep_ack);
                return false;
            },
            else => {
                if (length > 0) try r.discardAll(length);
                try writeOptionReplyEmpty(w, option, nbd.rep_err_unsup);
            },
        }
    }
}

fn writeOptionReply(w: *Io.Writer, option: u32, rep_type: u32, data: []const u8) !void {
    try w.writeInt(u64, nbd.rep_magic, .big);
    try w.writeInt(u32, option, .big);
    try w.writeInt(u32, rep_type, .big);
    try w.writeInt(u32, @intCast(data.len), .big);
    if (data.len > 0) try w.writeAll(data);
    try w.flush();
}

fn writeOptionReplyEmpty(w: *Io.Writer, option: u32, rep_type: u32) !void {
    try writeOptionReply(w, option, rep_type, &.{});
}

/// Send the (simple- or structured-reply, depending on `structured`)
/// acknowledgement for a non-`READ` request.
fn sendAck(w: *Io.Writer, structured: bool, cookie: u64, ok: bool) !void {
    if (structured) {
        try w.writeInt(u32, nbd.structured_reply_magic, .big);
        try w.writeInt(u16, nbd.reply_flag_done, .big);
        try w.writeInt(u16, if (ok) nbd.reply_type_none else nbd.reply_type_error, .big);
        try w.writeInt(u64, cookie, .big);
        if (ok) {
            try w.writeInt(u32, 0, .big);
        } else {
            try w.writeInt(u32, 6, .big); // error(4) + message_length(2), no message
            try w.writeInt(u32, nbd_eio, .big);
            try w.writeInt(u16, 0, .big);
        }
    } else {
        try w.writeInt(u32, nbd.simple_reply_magic, .big);
        try w.writeInt(u32, if (ok) @as(u32, 0) else nbd_eio, .big);
        try w.writeInt(u64, cookie, .big);
    }
    try w.flush();
}

fn handleRequest(
    allocator: std.mem.Allocator,
    r: *Io.Reader,
    w: *Io.Writer,
    req: nbd.RequestHeader,
    backing: *RawFile,
    structured_replies: bool,
) !void {
    switch (req.type) {
        nbd.cmd_read => {
            const buf = try allocator.alloc(u8, req.length);
            defer allocator.free(buf);
            const ok = if (backing.read(req.offset, buf)) |_| true else |_| false;
            if (structured_replies) {
                if (ok) {
                    try w.writeInt(u32, nbd.structured_reply_magic, .big);
                    try w.writeInt(u16, nbd.reply_flag_done, .big);
                    try w.writeInt(u16, nbd.reply_type_offset_data, .big);
                    try w.writeInt(u64, req.cookie, .big);
                    try w.writeInt(u32, @intCast(8 + buf.len), .big);
                    try w.writeInt(u64, req.offset, .big);
                    try w.writeAll(buf);
                } else {
                    try w.writeInt(u32, nbd.structured_reply_magic, .big);
                    try w.writeInt(u16, nbd.reply_flag_done, .big);
                    try w.writeInt(u16, nbd.reply_type_error, .big);
                    try w.writeInt(u64, req.cookie, .big);
                    try w.writeInt(u32, 6, .big);
                    try w.writeInt(u32, nbd_eio, .big);
                    try w.writeInt(u16, 0, .big);
                }
                try w.flush();
            } else {
                try w.writeInt(u32, nbd.simple_reply_magic, .big);
                try w.writeInt(u32, if (ok) @as(u32, 0) else nbd_eio, .big);
                try w.writeInt(u64, req.cookie, .big);
                if (ok) try w.writeAll(buf);
                try w.flush();
            }
        },
        nbd.cmd_write => {
            const data = try allocator.alloc(u8, req.length);
            defer allocator.free(data);
            try r.readSliceAll(data);
            const ok = if (backing.write(req.offset, data)) |_| true else |_| false;
            try sendAck(w, structured_replies, req.cookie, ok);
        },
        nbd.cmd_flush => {
            const ok = if (backing.flush()) |_| true else |_| false;
            try sendAck(w, structured_replies, req.cookie, ok);
        },
        nbd.cmd_trim => {
            // No-op: servers MAY ignore TRIM entirely (it's only a hint).
            try sendAck(w, structured_replies, req.cookie, true);
        },
        nbd.cmd_write_zeroes => {
            var zero_buf: [65536]u8 = @splat(0);
            var remaining: u64 = req.length;
            var off = req.offset;
            var ok = true;
            while (remaining > 0) {
                const chunk: usize = @intCast(@min(remaining, zero_buf.len));
                if (backing.write(off, zero_buf[0..chunk])) |_| {} else |_| {
                    ok = false;
                    break;
                }
                off += chunk;
                remaining -= chunk;
            }
            try sendAck(w, structured_replies, req.cookie, ok);
        },
        nbd.cmd_disc => {}, // no reply; caller returns after this
        else => try sendAck(w, structured_replies, req.cookie, false),
    }
}

/// Convenience wrapper: listen on the Unix domain socket at `socket_path`
/// and serve `backing` as `export_name` to one client at a time, forever
/// (each connection is fully handled by `serveOne` before the next is
/// accepted). A failed/dropped client session is logged and does not stop
/// the server.
pub fn listenAndServeUnix(allocator: std.mem.Allocator, io: Io, socket_path: []const u8, export_name: []const u8, backing: *RawFile) !void {
    const addr = try net.UnixAddress.init(socket_path);
    var listener = try addr.listen(io, .{});
    defer listener.deinit(io);

    while (true) {
        const stream = try listener.accept(io);
        defer stream.close(io);
        serveOne(allocator, io, stream, export_name, backing) catch |err| {
            std.log.warn("nbd: client session ended: {s}", .{@errorName(err)});
        };
    }
}

// ---------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------

const testing = std.testing;

test "serveOne <-> Client end-to-end over a real Unix socket" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const disk_size: u64 = 65536;
    {
        const f = try tmp.dir.createFile(io, "disk.raw", .{ .read = true });
        defer f.close(io);
        try f.setLength(io, disk_size);
        var pattern: [disk_size]u8 = undefined;
        for (&pattern, 0..) |*b, i| b.* = @truncate(i);
        try f.writePositionalAll(io, &pattern, 0);
    }

    var backing = try RawFile.open(io, tmp.dir, "disk.raw");
    defer backing.close();

    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const hex = std.fmt.bytesToHex(rand_bytes, .lower);
    var sock_path_buf: [64]u8 = undefined;
    const sock_path = try std.fmt.bufPrint(&sock_path_buf, "/tmp/nbd-test-{s}.sock", .{&hex});
    defer Io.Dir.deleteFileAbsolute(io, sock_path) catch {};

    const addr = try net.UnixAddress.init(sock_path);
    var listener = try addr.listen(io, .{});
    defer listener.deinit(io);

    const Context = struct {
        io: Io,
        listener: *net.Server,
        backing: *RawFile,
        allocator: std.mem.Allocator,
    };
    var ctx = Context{ .io = io, .listener = &listener, .backing = &backing, .allocator = a };

    const thread = try std.Thread.spawn(.{}, struct {
        fn run(c: *Context) void {
            const stream = c.listener.accept(c.io) catch return;
            defer stream.close(c.io);
            serveOne(c.allocator, c.io, stream, "test", c.backing) catch {};
        }
    }.run, .{&ctx});

    var client = try nbd.Client.connectUnix(a, io, sock_path, "test");
    defer client.close();

    try testing.expectEqual(disk_size, client.export_size);
    try testing.expect(client.structured_replies);
    try testing.expect(client.transmission_flags & nbd.flag_send_flush != 0);

    var out: [disk_size]u8 = undefined;
    try client.read(0, &out);
    var expected: [disk_size]u8 = undefined;
    for (&expected, 0..) |*b, i| b.* = @truncate(i);
    try testing.expectEqualSlices(u8, &expected, &out);

    const patch = "hello from the client";
    try client.write(100, patch);
    try client.flush();

    var readback: [patch.len]u8 = undefined;
    try client.read(100, &readback);
    try testing.expectEqualStrings(patch, &readback);

    try client.disconnect();
    thread.join();
}
