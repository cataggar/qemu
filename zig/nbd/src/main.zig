//! nbd CLI — a small demo/validation tool over the native Zig NBD client
//! (and a minimal reference server).
//!
//!   nbd info  <target> <export>                  print export size + transmission flags
//!   nbd read  <target> <export> <offset> <len>    write raw bytes to stdout
//!   nbd write <target> <export> <offset>          write stdin bytes to the export
//!   nbd flush <target> <export>                   issue NBD_CMD_FLUSH
//!   nbd serve <target> <export> <raw-file>        serve <raw-file> as <export> forever
//!                                                  (<target> must be unix:<path>)
//!
//! <target> is `unix:<path>` or `tcp:<host>:<port>`.

const std = @import("std");
const Io = std.Io;
const nbd = @import("nbd");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_fw: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const out = &stdout_fw.interface;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 4) {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    const cmd = args[1];
    const target = args[2];
    const export_name = args[3];

    if (std.mem.eql(u8, cmd, "serve")) {
        if (args.len < 5) return error.Usage;
        try serveCmd(arena, io, target, export_name, args[4]);
        return;
    }

    const client = try connect(arena, io, target, export_name);
    defer client.close();

    if (std.mem.eql(u8, cmd, "info")) {
        try infoCmd(out, client);
    } else if (std.mem.eql(u8, cmd, "read")) {
        if (args.len < 6) return error.Usage;
        const off = try std.fmt.parseInt(u64, args[4], 0);
        const len = try std.fmt.parseInt(usize, args[5], 0);
        const buf = try arena.alloc(u8, len);
        try client.read(off, buf);
        try out.writeAll(buf);
    } else if (std.mem.eql(u8, cmd, "write")) {
        if (args.len < 5) return error.Usage;
        const off = try std.fmt.parseInt(u64, args[4], 0);
        var stdin_buf: [8192]u8 = undefined;
        var stdin_fr: Io.File.Reader = .init(.stdin(), io, &stdin_buf);
        const data = try stdin_fr.interface.allocRemaining(arena, .unlimited);
        try client.write(off, data);
    } else if (std.mem.eql(u8, cmd, "flush")) {
        try client.flush();
    } else {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    try out.flush();
}

/// Parse `unix:<path>` or `tcp:<host>:<port>` and connect + negotiate
/// `export_name`.
fn connect(allocator: std.mem.Allocator, io: Io, target: []const u8, export_name: []const u8) !*nbd.Client {
    if (std.mem.startsWith(u8, target, "unix:")) {
        return nbd.Client.connectUnix(allocator, io, target["unix:".len..], export_name);
    }
    if (std.mem.startsWith(u8, target, "tcp:")) {
        const host_port = target["tcp:".len..];
        const idx = std.mem.lastIndexOfScalar(u8, host_port, ':') orelse return error.InvalidTarget;
        const host = host_port[0..idx];
        const port = try std.fmt.parseInt(u16, host_port[idx + 1 ..], 10);
        const addr = try Io.net.IpAddress.resolve(io, host, port);
        return nbd.Client.connectTcp(allocator, io, addr, export_name);
    }
    return error.InvalidTarget;
}

fn usage(out: *Io.Writer) !void {
    try out.writeAll(
        \\usage:
        \\  nbd info  <target> <export>                 print export size + transmission flags
        \\  nbd read  <target> <export> <offset> <len>   write raw bytes to stdout
        \\  nbd write <target> <export> <offset>         write stdin bytes to the export
        \\  nbd flush <target> <export>                  issue NBD_CMD_FLUSH
        \\  nbd serve <target> <export> <raw-file>       serve <raw-file> as <export> forever
        \\                                                (<target> must be unix:<path>)
        \\
        \\<target> is unix:<path> or tcp:<host>:<port>
        \\
    );
}

/// `serve <unix:path> <export> <raw-file>`: serve `<raw-file>` as `<export>`
/// forever, one client connection at a time.
fn serveCmd(allocator: std.mem.Allocator, io: Io, target: []const u8, export_name: []const u8, raw_path: []const u8) !void {
    if (!std.mem.startsWith(u8, target, "unix:")) return error.InvalidTarget;
    const socket_path = target["unix:".len..];
    var backing = try nbd.server.RawFile.open(io, Io.Dir.cwd(), raw_path);
    defer backing.close();
    try nbd.server.listenAndServeUnix(allocator, io, socket_path, export_name, &backing);
}

fn infoCmd(out: *Io.Writer, client: *nbd.Client) !void {
    const f = client.transmission_flags;
    try out.print("export size:        {d} bytes\n", .{client.export_size});
    try out.print("structured replies: {}\n", .{client.structured_replies});
    try out.print("transmission flags: 0x{x}\n", .{f});
    try out.print("  read-only:         {}\n", .{f & nbd.flag_read_only != 0});
    try out.print("  flush:             {}\n", .{f & nbd.flag_send_flush != 0});
    try out.print("  fua:               {}\n", .{f & nbd.flag_send_fua != 0});
    try out.print("  trim:              {}\n", .{f & nbd.flag_send_trim != 0});
    try out.print("  write_zeroes:      {}\n", .{f & nbd.flag_send_write_zeroes != 0});
    try out.print("  rotational:        {}\n", .{f & nbd.flag_rotational != 0});
    try out.print("  can_multi_conn:    {}\n", .{f & nbd.flag_can_multi_conn != 0});
}
