//! qcow2 CLI — a small demo/validation tool over the native Zig qcow2 reader.
//!
//!   qcow2 info  <image>                 dump header + feature summary
//!   qcow2 map   <image> <offset>        classify the cluster at a guest offset
//!   qcow2 read  <image> <offset> <len>  write `len` bytes from the guest disk
//!                                        to stdout (raw)

const std = @import("std");
const Io = std.Io;
const qcow2 = @import("qcow2");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_fw: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const out = &stdout_fw.interface;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 3) {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    const cmd = args[1];
    const path = args[2];

    var img = try qcow2.Image.open(arena, io, Io.Dir.cwd(), path);
    defer img.close();

    if (std.mem.eql(u8, cmd, "info")) {
        try info(out, &img);
    } else if (std.mem.eql(u8, cmd, "map")) {
        if (args.len < 4) return error.Usage;
        const off = try std.fmt.parseInt(u64, args[3], 0);
        try mapCmd(out, &img, off);
    } else if (std.mem.eql(u8, cmd, "read")) {
        if (args.len < 5) return error.Usage;
        const off = try std.fmt.parseInt(u64, args[3], 0);
        const len = try std.fmt.parseInt(usize, args[4], 0);
        const buf = try arena.alloc(u8, len);
        try img.read(off, buf);
        try out.writeAll(buf);
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
        \\  qcow2 info <image>
        \\  qcow2 map  <image> <offset>
        \\  qcow2 read <image> <offset> <len>   (raw bytes to stdout)
        \\
    );
}

fn info(out: *Io.Writer, img: *qcow2.Image) !void {
    const h = img.header;
    try out.print("version:            {d}\n", .{h.version});
    try out.print("virtual size:       {d} bytes\n", .{h.size});
    try out.print("cluster size:       {d} bytes\n", .{h.clusterSize()});
    try out.print("l1 entries:         {d}\n", .{h.l1_size});
    try out.print("l2 entries/table:   {d}\n", .{h.l2Entries()});
    try out.print("snapshots:          {d}\n", .{h.nb_snapshots});
    try out.print("has backing file:   {}\n", .{h.backing_file_offset != 0});
    if (img.backing_name) |name| try out.print("backing file:       {s}\n", .{name});
    try out.print("compression type:   {s}\n", .{if (h.compression_type == 1) "zstd" else "deflate"});
    try out.print("incompatible bits:  0x{x}\n", .{h.incompatible_features});
    try out.print("  non-default compression: {}\n", .{h.hasIncompatible(.compression_type)});
    try out.print("  external data file:  {}\n", .{h.hasIncompatible(.external_data_file)});
    try out.print("  extended L2:         {}\n", .{h.hasIncompatible(.extended_l2)});
}

fn mapCmd(out: *Io.Writer, img: *qcow2.Image, off: u64) !void {
    const m = try img.mapCluster(off);
    switch (m) {
        .unallocated => try out.writeAll("unallocated\n"),
        .zero => try out.writeAll("zero\n"),
        .compressed => |ref| try out.print("compressed @ 0x{x} ({d} bytes)\n", .{ ref.coffset, ref.csize }),
        .standard => |host| try out.print("standard @ host offset 0x{x}\n", .{host}),
    }
}
