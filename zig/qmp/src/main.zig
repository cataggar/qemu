//! qmp CLI — a small demo/validation tool over the native Zig QMP client.
//!
//!   qmp greeting <socket>                 connect, print the server greeting, disconnect
//!   qmp exec     <socket> <command> [json-args]
//!                                          connect, execute <command> (with optional
//!                                          JSON arguments), print the return value
//!                                          (or error) to stdout, disconnect
//!   qmp watch    <socket> <count>          connect, print <count> events (blocking), disconnect
//!   qmp spawn-status <qemu-binary> [extra-args...]
//!                                          spawn <qemu-binary> via Client.spawnAndConnect,
//!                                          run the typed qapi.queryStatus binding, print
//!                                          its result, then qapi.quit it

const std = @import("std");
const Io = std.Io;
const qmp = @import("qmp");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_fw: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const out = &stdout_fw.interface;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    const cmd = args[1];

    if (std.mem.eql(u8, cmd, "spawn-status")) {
        if (args.len < 3) return error.Usage;
        try spawnStatusCmd(arena, io, out, args[2], args[3..]);
        try out.flush();
        return;
    }

    if (args.len < 3) {
        try usage(out);
        try out.flush();
        return error.Usage;
    }
    const socket_path = args[2];

    if (std.mem.eql(u8, cmd, "greeting")) {
        try greetingCmd(arena, io, out, socket_path);
    } else if (std.mem.eql(u8, cmd, "exec")) {
        if (args.len < 4) return error.Usage;
        const json_args = if (args.len >= 5) args[4] else null;
        const ok = try execCmd(arena, io, out, socket_path, args[3], json_args);
        try out.flush();
        if (!ok) return error.CommandFailed;
        return;
    } else if (std.mem.eql(u8, cmd, "watch")) {
        if (args.len < 4) return error.Usage;
        const count = try std.fmt.parseInt(u32, args[3], 0);
        try watchCmd(arena, io, out, socket_path, count);
    } else {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    try out.flush();
}

fn usage(out: *Io.Writer) !void {
    try out.writeAll(
        \\usage:
        \\  qmp greeting <socket>                 print the server greeting
        \\  qmp exec     <socket> <command> [json-args]
        \\                                         run a command, print its result
        \\  qmp watch    <socket> <count>          print <count> events (blocking)
        \\  qmp spawn-status <qemu-binary> [extra-args...]
        \\                                         spawn + connect, run the typed
        \\                                         qapi.queryStatus binding, then quit
        \\
    );
}

fn greetingCmd(allocator: std.mem.Allocator, io: Io, out: *Io.Writer, socket_path: []const u8) !void {
    const client = try qmp.Client.connectUnix(allocator, io, socket_path);
    defer client.close();

    try std.json.Stringify.value(client.greeting.value, .{ .whitespace = .indent_2 }, out);
    try out.writeByte('\n');
}

/// Returns whether the command succeeded (used by `main` to decide the
/// process exit code).
fn execCmd(
    allocator: std.mem.Allocator,
    io: Io,
    out: *Io.Writer,
    socket_path: []const u8,
    command: []const u8,
    json_args: ?[]const u8,
) !bool {
    const client = try qmp.Client.connectUnix(allocator, io, socket_path);
    defer client.close();

    var parsed_args: ?std.json.Parsed(std.json.Value) = null;
    defer if (parsed_args) |p| p.deinit();
    const args: ?std.json.Value = if (json_args) |s| blk: {
        parsed_args = try std.json.parseFromSlice(std.json.Value, allocator, s, .{});
        break :blk parsed_args.?.value;
    } else null;

    var reply = try client.execute(command, args);
    defer reply.deinit();

    if (reply.err) |e| {
        try out.print("error: {s}: {s}\n", .{ e.class, e.desc });
        return false;
    }

    try std.json.Stringify.value(reply.result.?, .{ .whitespace = .indent_2 }, out);
    try out.writeByte('\n');
    return true;
}

fn watchCmd(allocator: std.mem.Allocator, io: Io, out: *Io.Writer, socket_path: []const u8, count: u32) !void {
    const client = try qmp.Client.connectUnix(allocator, io, socket_path);
    defer client.close();

    var i: u32 = 0;
    while (i < count) : (i += 1) {
        var ev = try client.waitEvent();
        defer ev.deinit();
        try out.print("event={s} seconds={d} microseconds={d}\n", .{ ev.name, ev.seconds, ev.microseconds });
        if (ev.data) |d| {
            try std.json.Stringify.value(d, .{ .whitespace = .indent_2 }, out);
            try out.writeByte('\n');
        }
    }
}

/// `spawn-status <qemu-binary> [extra-args...]`: exercises `spawnAndConnect`
/// plus the QAPI-generated typed bindings end-to-end -- launches
/// `qemu-binary`, waits for its QMP socket, runs the typed `queryStatus`
/// command, prints the (typed, not raw-JSON) result, then `quit`s it.
fn spawnStatusCmd(
    allocator: std.mem.Allocator,
    io: Io,
    out: *Io.Writer,
    binary: []const u8,
    extra_args: []const []const u8,
) !void {
    var spawned = try qmp.spawnAndConnect(allocator, io, .{
        .binary = binary,
        .extra_args = extra_args,
    });
    defer spawned.deinit();

    var status = try qmp.qapi.queryStatus(spawned.client, allocator);
    defer status.deinit();
    try out.print("running={} status={s}\n", .{ status.value.running, @tagName(status.value.status) });

    var quit_reply = try qmp.qapi.quit(spawned.client, allocator);
    defer quit_reply.deinit();

    const term = try spawned.wait();
    try out.print("term={any}\n", .{term});
}
