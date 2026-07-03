//! qcow2 CLI — a small demo/validation tool over the native Zig qcow2 reader.
//!
//!   qcow2 info      <image>                 dump header + feature summary
//!   qcow2 map       <image> <offset>        classify the cluster at a guest offset
//!   qcow2 read      <image> <offset> <len> [--snapshot=<id>]
//!                                            write `len` bytes from the guest disk
//!                                            (or a snapshot's) to stdout (raw)
//!   qcow2 check     <image>                 basic refcount/consistency check
//!   qcow2 snapshots <image>                 list the snapshot directory

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

    // Commands that create an image (don't open an existing one first).
    if (std.mem.eql(u8, cmd, "convert")) {
        if (args.len < 4) return error.Usage;
        try convertCmd(arena, io, args[2], args[3]);
        return;
    }

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
        if (args.len >= 6 and std.mem.startsWith(u8, args[5], "--snapshot=")) {
            try readSnapshotCmd(arena, &img, args[5]["--snapshot=".len..], off, buf);
        } else {
            try img.read(off, buf);
        }
        try out.writeAll(buf);
    } else if (std.mem.eql(u8, cmd, "check")) {
        const clean = try checkCmd(out, arena, &img);
        try out.flush();
        if (!clean) return error.ChecksFailed;
        return;
    } else if (std.mem.eql(u8, cmd, "snapshots")) {
        try snapshotsCmd(out, arena, &img);
    } else {
        try usage(out);
        try out.flush();
        return error.Usage;
    }

    try out.flush();
}

/// `convert <raw_in> <qcow2_out>`: create a qcow2 image from a raw file.
fn convertCmd(arena: std.mem.Allocator, io: Io, raw_path: []const u8, out_path: []const u8) !void {
    const in = try Io.Dir.cwd().openFile(io, raw_path, .{ .mode = .read_only });
    defer in.close(io);
    const st = try in.stat(io);
    const data = try arena.alloc(u8, @intCast(st.size));
    const got = try in.readPositionalAll(io, data, 0);
    if (got != data.len) return error.Truncated;
    try qcow2.writer.createFromRaw(arena, io, Io.Dir.cwd(), out_path, data, st.size, .{});
}

fn usage(out: *Io.Writer) !void {
    try out.writeAll(
        \\usage:
        \\  qcow2 info <image>
        \\  qcow2 map  <image> <offset>
        \\  qcow2 read <image> <offset> <len> [--snapshot=<id>]  (raw bytes to stdout)
        \\  qcow2 check <image>                 (basic refcount/consistency check)
        \\  qcow2 snapshots <image>              (list the snapshot directory)
        \\  qcow2 convert <raw_in> <qcow2_out>  (create qcow2 from a raw file)
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

    // Extended L2 images resolve standard/zero/unallocated status per
    // subcluster (compressed clusters have no subclusters); report which
    // subcluster this offset falls in.
    const h = img.header;
    if (h.hasIncompatible(.extended_l2) and std.meta.activeTag(m) != .compressed) {
        const index = (off % h.clusterSize()) / h.subclusterSize();
        try out.print("subcluster:         {d} of {d}\n", .{ index, qcow2.Header.subclusters_per_cluster });
    }
}

/// `check <image>`: run Image.check and print a qemu-img-check-style
/// summary. Returns whether the image was clean (used by main to decide the
/// process exit code).
fn checkCmd(out: *Io.Writer, allocator: std.mem.Allocator, img: *qcow2.Image) !bool {
    var report = try img.check(allocator);
    defer report.deinit(allocator);

    if (report.isClean()) {
        try out.print("No errors were found on the image.\n", .{});
        try out.print("{d} clusters referenced.\n", .{report.allocated_clusters});
        return true;
    }

    for (report.findings.items) |f| {
        switch (f.kind) {
            .used_cluster_zero_refcount => try out.print(
                "ERROR: cluster {d} is used but has a stored refcount of 0\n",
                .{f.cluster_index},
            ),
            .refcount_mismatch => try out.print(
                "ERROR: cluster {d} has refcount {d}, but {d} reference(s) were found\n",
                .{ f.cluster_index, f.stored, f.computed },
            ),
            .leaked_cluster => try out.print(
                "Leaked cluster {d} refcount={d} (not referenced by any metadata)\n",
                .{ f.cluster_index, f.stored },
            ),
        }
    }
    try out.print("{d} errors were found on the image.\n", .{report.findings.items.len});
    return false;
}

/// `read ... --snapshot=<id>`: find the snapshot whose id or name matches
/// `id_or_name` and read from it instead of the active image.
fn readSnapshotCmd(
    allocator: std.mem.Allocator,
    img: *qcow2.Image,
    id_or_name: []const u8,
    off: u64,
    buf: []u8,
) !void {
    const snaps = try img.snapshots(allocator);
    for (snaps) |s| {
        if (std.mem.eql(u8, s.id, id_or_name) or std.mem.eql(u8, s.name, id_or_name)) {
            var view = try img.openSnapshot(allocator, s);
            defer view.deinit();
            try view.read(off, buf);
            return;
        }
    }
    return error.SnapshotNotFound;
}

/// `snapshots <image>`: list the snapshot directory.
fn snapshotsCmd(out: *Io.Writer, allocator: std.mem.Allocator, img: *qcow2.Image) !void {
    const snaps = try img.snapshots(allocator);
    if (snaps.len == 0) {
        try out.writeAll("(no snapshots)\n");
        return;
    }
    for (snaps) |s| {
        try out.print(
            "id={s}  name={s}  size={d} bytes  date={d}.{d:0>9}\n",
            .{ s.id, s.name, s.disk_size, s.date_sec, s.date_nsec },
        );
    }
}
