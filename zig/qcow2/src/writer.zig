//! qcow2 image writer / creator (native Zig).
//!
//! Builds a valid qcow2 v3 image in memory from raw guest data, then writes it
//! to a file. Produces refcount table/blocks, L1/L2 tables, and data clusters.
//! All-zero guest clusters are left unallocated (they read back as zeros).
//! Optionally emits Extended L2 Entries (`CreateOptions.extended_l2`), with
//! every subcluster of an allocated cluster marked allocated.
//!
//! Scope: uncompressed v3 images without a backing file, snapshots, or
//! encryption. Validated against `qemu-img check` / `qemu-img convert`.

const std = @import("std");
const Io = std.Io;
const qcow2 = @import("qcow2.zig");

const oflag_copied: u64 = @as(u64, 1) << 63; // refcount is exactly one

pub const CreateOptions = struct {
    cluster_bits: u5 = 16, // 64 KiB clusters
    /// Emit Extended L2 Entries (16-byte L2 entries with a per-subcluster
    /// allocation bitmap) instead of standard 8-byte entries. Every
    /// subcluster of an allocated cluster is marked allocated (no zero
    /// subclusters are produced); `cluster_bits` must be >= 14.
    extended_l2: bool = false,
};

/// Create a qcow2 image at `path` whose contents are `data` (zero-padded /
/// truncated to `virtual_size`). All-zero clusters are stored unallocated.
pub fn createFromRaw(
    allocator: std.mem.Allocator,
    io: Io,
    dir: Io.Dir,
    path: []const u8,
    data: []const u8,
    virtual_size: u64,
    opts: CreateOptions,
) !void {
    const cluster_bits: u6 = opts.cluster_bits;
    if (opts.extended_l2 and cluster_bits < 14) return error.BadClusterBits;
    const cs: u64 = @as(u64, 1) << cluster_bits;
    // qcow2 virtual sizes are sector-granular; round up to 512 like qemu-img.
    const vsize = std.mem.alignForward(u64, virtual_size, 512);
    const l2_entry_size: u64 = if (opts.extended_l2) 16 else 8;
    const l2_entries: u64 = cs / l2_entry_size;
    const refcount_bits: u64 = 16;
    const rb_entries: u64 = cs * 8 / refcount_bits; // refcount block entries

    const num_guest_clusters = (vsize + cs - 1) / cs;
    const l1_size: u64 = (num_guest_clusters + l2_entries - 1) / l2_entries;

    // The image is built as a flat sequence of clusters in memory.
    var file: std.ArrayList(u8) = .empty;
    defer file.deinit(allocator);

    const Ctx = struct {
        file: *std.ArrayList(u8),
        allocator: std.mem.Allocator,
        cs: u64,

        fn alloc(self: @This()) !u64 {
            const idx = self.file.items.len / self.cs;
            try self.file.appendNTimes(self.allocator, 0, @intCast(self.cs));
            return idx;
        }
        fn put64(self: @This(), off: u64, val: u64) void {
            std.mem.writeInt(u64, self.file.items[@intCast(off)..][0..8], val, .big);
        }
        fn put16(self: @This(), off: u64, val: u16) void {
            std.mem.writeInt(u16, self.file.items[@intCast(off)..][0..2], val, .big);
        }
    };
    const ctx: Ctx = .{ .file = &file, .allocator = allocator, .cs = cs };

    // Fixed early clusters: header (0), refcount table (1), then L1 table.
    _ = try ctx.alloc(); // cluster 0: header
    const rt_offset = (try ctx.alloc()) * cs; // refcount table (1 cluster)
    const refcount_table_clusters: u64 = 1;

    const l1_clusters = if (l1_size == 0) 0 else (l1_size * 8 + cs - 1) / cs;
    var l1_offset: u64 = 0;
    {
        var i: u64 = 0;
        while (i < l1_clusters) : (i += 1) {
            const c = try ctx.alloc();
            if (i == 0) l1_offset = c * cs;
        }
    }

    // Track allocated L2 tables per L1 index (0 = not yet allocated).
    const l2_table_offset = try allocator.alloc(u64, @intCast(l1_size));
    defer allocator.free(l2_table_offset);
    @memset(l2_table_offset, 0);

    // Place data clusters.
    var g: u64 = 0;
    while (g < num_guest_clusters) : (g += 1) {
        const start = g * cs;
        const avail: usize = if (start >= data.len) 0 else @intCast(@min(cs, data.len - start));
        const src = data[@intCast(@min(start, data.len))..][0..avail];
        if (isAllZero(src)) continue; // unallocated -> reads as zero

        const l1_idx = g / l2_entries;
        const l2_idx = g % l2_entries;

        if (l2_table_offset[@intCast(l1_idx)] == 0) {
            const l2c = (try ctx.alloc()) * cs;
            l2_table_offset[@intCast(l1_idx)] = l2c;
            ctx.put64(l1_offset + l1_idx * 8, l2c | oflag_copied);
        }
        const l2_off = l2_table_offset[@intCast(l1_idx)];

        const datac = (try ctx.alloc()) * cs;
        @memcpy(file.items[@intCast(datac)..][0..avail], src);
        const l2e_off = l2_off + l2_idx * l2_entry_size;
        ctx.put64(l2e_off, datac | oflag_copied);
        if (opts.extended_l2) {
            // Every subcluster of this cluster is allocated (bits 0-31);
            // no subcluster reads as zero (bits 32-63 stay clear).
            ctx.put64(l2e_off + 8, 0xffff_ffff);
        }
    }

    // Allocate refcount blocks to cover every cluster (including the blocks
    // themselves), then set all refcounts to 1.
    const rt_entries = cs / 8;
    const refcount_table = try allocator.alloc(u64, @intCast(rt_entries));
    defer allocator.free(refcount_table);
    @memset(refcount_table, 0);

    while (true) {
        const total = file.items.len / cs;
        const needed = (total + rb_entries - 1) / rb_entries;
        var allocated_new = false;
        var i: u64 = 0;
        while (i < needed) : (i += 1) {
            if (refcount_table[@intCast(i)] == 0) {
                refcount_table[@intCast(i)] = (try ctx.alloc()) * cs;
                allocated_new = true;
            }
        }
        if (!allocated_new) break;
    }

    // Write refcount table entries and set every cluster's refcount to 1.
    {
        const total = file.items.len / cs;
        var i: u64 = 0;
        while (i * rb_entries < total or (i == 0 and total == 0)) : (i += 1) {
            if (refcount_table[@intCast(i)] == 0) break;
            ctx.put64(rt_offset + i * 8, refcount_table[@intCast(i)]);
        }
        var h: u64 = 0;
        while (h < total) : (h += 1) {
            const table_index = h / rb_entries;
            const block_index = h % rb_entries;
            const rb_off = refcount_table[@intCast(table_index)];
            ctx.put16(rb_off + block_index * 2, 1);
        }
    }

    // Header (cluster 0).
    writeHeader(file.items[0..], .{
        .cluster_bits = @intCast(cluster_bits),
        .size = vsize,
        .l1_size = l1_size,
        .l1_table_offset = l1_offset,
        .refcount_table_offset = rt_offset,
        .refcount_table_clusters = refcount_table_clusters,
        .incompatible_features = if (opts.extended_l2) (@as(u64, 1) << 4) else 0,
    });

    // Flush to disk.
    const out = try dir.createFile(io, path, .{ .truncate = true });
    defer out.close(io);
    try out.writePositionalAll(io, file.items, 0);
}

const HeaderFields = struct {
    cluster_bits: u32,
    size: u64,
    l1_size: u64,
    l1_table_offset: u64,
    refcount_table_offset: u64,
    refcount_table_clusters: u64,
    incompatible_features: u64 = 0,
};

fn writeHeader(buf: []u8, f: HeaderFields) void {
    @memset(buf[0..104], 0);
    std.mem.writeInt(u32, buf[0..4], qcow2.magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big); // version
    // backing_file_offset (8), backing_file_size (16) left 0
    std.mem.writeInt(u32, buf[20..24], f.cluster_bits, .big);
    std.mem.writeInt(u64, buf[24..32], f.size, .big);
    // crypt_method (32) = 0
    std.mem.writeInt(u32, buf[36..40], @intCast(f.l1_size), .big);
    std.mem.writeInt(u64, buf[40..48], f.l1_table_offset, .big);
    std.mem.writeInt(u64, buf[48..56], f.refcount_table_offset, .big);
    std.mem.writeInt(u32, buf[56..60], @intCast(f.refcount_table_clusters), .big);
    // nb_snapshots (60) = 0, snapshots_offset (64) = 0
    // v3 fields:
    std.mem.writeInt(u64, buf[72..80], f.incompatible_features, .big);
    std.mem.writeInt(u64, buf[80..88], 0, .big); // compatible_features
    std.mem.writeInt(u64, buf[88..96], 0, .big); // autoclear_features
    std.mem.writeInt(u32, buf[96..100], 4, .big); // refcount_order = 4 (16-bit)
    std.mem.writeInt(u32, buf[100..104], 104, .big); // header_length
}

fn isAllZero(bytes: []const u8) bool {
    for (bytes) |b| if (b != 0) return false;
    return true;
}
