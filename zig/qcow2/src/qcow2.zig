//! Native Zig qcow2 image reader.
//!
//! A dependency-free, clean-room implementation of the qcow2 on-disk format
//! (see `docs/interop/qcow2.rst` in the QEMU tree). No QEMU C code is used.
//!
//! Scope: read path for v2/v3 images, including standard, zero, unallocated,
//! and compressed clusters, backing-file chains, and Extended L2 Entries
//! (per-subcluster allocation). See `writer.zig` for image creation.
//!
//! All multi-byte integers in qcow2 are stored big-endian.

const std = @import("std");
const Io = std.Io;
const flate = std.compress.flate;
const zstd = std.compress.zstd;

pub const magic: u32 = 0x514649fb; // "QFI\xfb"

/// Image creation / writer support.
pub const writer = @import("writer.zig");

/// Header field offsets and layout, per the qcow2 spec.
pub const Header = struct {
    version: u32,
    backing_file_offset: u64,
    backing_file_size: u32,
    cluster_bits: u32,
    size: u64, // virtual disk size in bytes
    crypt_method: u32,
    l1_size: u32, // number of active L1 entries
    l1_table_offset: u64,
    refcount_table_offset: u64,
    refcount_table_clusters: u32,
    nb_snapshots: u32,
    snapshots_offset: u64,

    // v3+ fields (zero for v2).
    incompatible_features: u64 = 0,
    compatible_features: u64 = 0,
    autoclear_features: u64 = 0,
    refcount_order: u32 = 4, // refcount_bits = 1 << refcount_order; default 4 => 16-bit
    header_length: u32 = 72,
    compression_type: u8 = 0, // 0 = deflate, 1 = zstd

    pub const IncompatibleBit = enum(u6) {
        dirty = 0,
        corrupt = 1,
        external_data_file = 2,
        compression_type = 3,
        extended_l2 = 4,
    };

    /// Number of subclusters per standard data cluster in Extended L2 images.
    pub const subclusters_per_cluster: u64 = 32;

    pub fn clusterSize(self: Header) u64 {
        return @as(u64, 1) << @intCast(self.cluster_bits);
    }

    /// Number of L2 entries per L2 table cluster. Extended L2 Entries
    /// (incompatible bit 4) use 16-byte entries instead of 8, halving the
    /// number of entries per table.
    pub fn l2Entries(self: Header) u64 {
        return self.clusterSize() / self.l2EntrySize();
    }

    /// Size in bytes of a single L2 entry: 16 for Extended L2 images, 8
    /// otherwise.
    pub fn l2EntrySize(self: Header) u64 {
        return if (self.hasIncompatible(.extended_l2)) 16 else @sizeOf(u64);
    }

    /// Size in bytes of a subcluster. Only meaningful for Extended L2
    /// images, which divide each standard data cluster into 32 subclusters.
    pub fn subclusterSize(self: Header) u64 {
        return self.clusterSize() / Header.subclusters_per_cluster;
    }

    pub fn hasIncompatible(self: Header, bit: IncompatibleBit) bool {
        return (self.incompatible_features & (@as(u64, 1) << @intFromEnum(bit))) != 0;
    }

    /// Parse a header from at least the first 104 bytes of an image.
    pub fn parse(buf: []const u8) Error!Header {
        if (buf.len < 72) return error.Truncated;
        if (rd32(buf, 0) != magic) return error.BadMagic;

        var h: Header = .{
            .version = rd32(buf, 4),
            .backing_file_offset = rd64(buf, 8),
            .backing_file_size = rd32(buf, 16),
            .cluster_bits = rd32(buf, 20),
            .size = rd64(buf, 24),
            .crypt_method = rd32(buf, 32),
            .l1_size = rd32(buf, 36),
            .l1_table_offset = rd64(buf, 40),
            .refcount_table_offset = rd64(buf, 48),
            .refcount_table_clusters = rd32(buf, 56),
            .nb_snapshots = rd32(buf, 60),
            .snapshots_offset = rd64(buf, 64),
        };

        if (h.version < 2 or h.version > 3) return error.UnsupportedVersion;
        if (h.cluster_bits < 9 or h.cluster_bits > 21) return error.BadClusterBits;

        if (h.version >= 3) {
            if (buf.len < 104) return error.Truncated;
            h.incompatible_features = rd64(buf, 72);
            h.compatible_features = rd64(buf, 80);
            h.autoclear_features = rd64(buf, 88);
            h.refcount_order = rd32(buf, 96);
            h.header_length = rd32(buf, 100);
            if (h.header_length >= 105 and buf.len > 104) {
                h.compression_type = buf[104];
            }
        }

        // Per spec: fail to open if an unknown incompatible bit is set.
        const known_incompatible: u64 =
            (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4);
        if ((h.incompatible_features & ~known_incompatible) != 0)
            return error.UnknownIncompatibleFeature;

        // Per spec: Extended L2 Entries require cluster_bits >= 14 (i.e.
        // clusters of at least 16 KiB, so a 16-byte L2 entry still leaves
        // room for a whole number of subclusters).
        if (h.hasIncompatible(.extended_l2) and h.cluster_bits < 14)
            return error.BadClusterBits;

        return h;
    }
};

pub const Error = error{
    Truncated,
    BadMagic,
    UnsupportedVersion,
    BadClusterBits,
    UnknownIncompatibleFeature,
    // Read path
    OutOfRange,
    UnsupportedCompressionType,
    CorruptMapping,
    DecompressFailed,
    BackingChainTooDeep,
};

/// Location of a compressed cluster's payload within the image file.
pub const CompressedRef = struct {
    coffset: u64, // exact byte offset of compressed data (not sector aligned)
    csize: u32, // number of compressed bytes to read
};

/// Classification of a single guest cluster's backing store.
pub const Mapping = union(enum) {
    unallocated, // read from backing file or zeros
    zero, // reads as zeros (zero bit set)
    standard: u64, // host file offset of the cluster data
    compressed: CompressedRef,
};

const l2e_offset_mask: u64 = 0x00fffffffffffe00; // bits 9..55
const l2e_compressed: u64 = @as(u64, 1) << 62;
const l1e_offset_mask: u64 = 0x00fffffffffffe00;
const standard_zero_bit: u64 = 1; // bit 0 of standard cluster descriptor

/// An opened qcow2 image. Backed by a file handle; caller owns lifetime via
/// `close`.
pub const Image = struct {
    io: Io,
    dir: Io.Dir,
    file: Io.File,
    header: Header,
    l1: []u64, // active L1 table, host-endian
    allocator: std.mem.Allocator,
    backing: ?*Image = null, // backing image in the chain, if any
    backing_name: ?[]u8 = null, // owned; the raw backing file name

    const max_backing_depth = 32;

    pub fn open(
        allocator: std.mem.Allocator,
        io: Io,
        dir: Io.Dir,
        path: []const u8,
    ) !Image {
        return openDepth(allocator, io, dir, path, 0);
    }

    fn openDepth(
        allocator: std.mem.Allocator,
        io: Io,
        dir: Io.Dir,
        path: []const u8,
        depth: u32,
    ) !Image {
        if (depth >= max_backing_depth) return error.BackingChainTooDeep;
        const file = try dir.openFile(io, path, .{ .mode = .read_only });
        errdefer file.close(io);

        // Read enough for the full v3 header including the compression_type
        // field at offset 104 and any leading padding.
        var head_buf: [512]u8 = undefined;
        const n = try file.readPositionalAll(io, &head_buf, 0);
        if (n < 72) return error.Truncated;
        const header = try Header.parse(head_buf[0..n]);

        // Read the active L1 table.
        const l1 = try allocator.alloc(u64, header.l1_size);
        errdefer allocator.free(l1);
        if (header.l1_size != 0) {
            const bytes = std.mem.sliceAsBytes(l1);
            const got = try file.readPositionalAll(io, bytes, header.l1_table_offset);
            if (got != bytes.len) return error.Truncated;
            for (l1) |*e| e.* = std.mem.bigToNative(u64, e.*);
        }

        var img: Image = .{
            .io = io,
            .dir = dir,
            .file = file,
            .header = header,
            .l1 = l1,
            .allocator = allocator,
        };

        // Open the backing image, if any. Its name is relative to the
        // directory containing this image (unless absolute).
        if (header.backing_file_offset != 0 and header.backing_file_size != 0) {
            if (header.backing_file_size > 1023) return error.CorruptMapping;
            const name = try allocator.alloc(u8, header.backing_file_size);
            errdefer allocator.free(name);
            const got = try file.readPositionalAll(io, name, header.backing_file_offset);
            if (got != name.len) return error.Truncated;
            img.backing_name = name;

            const full = try resolveBackingPath(allocator, path, name);
            defer allocator.free(full);
            const child = try allocator.create(Image);
            errdefer allocator.destroy(child);
            child.* = try openDepth(allocator, io, dir, full, depth + 1);
            img.backing = child;
        }

        return img;
    }

    pub fn close(self: *Image) void {
        if (self.backing) |b| {
            b.close();
            self.allocator.destroy(b);
        }
        if (self.backing_name) |name| self.allocator.free(name);
        self.allocator.free(self.l1);
        self.file.close(self.io);
        self.* = undefined;
    }

    /// Resolve the mapping for `guest_offset`. For standard clusters in an
    /// Extended L2 image this resolves down to the *subcluster* containing
    /// `guest_offset` (host offsets are adjusted to the subcluster's byte
    /// offset); compressed clusters have no subclusters and are always
    /// resolved at full cluster granularity.
    pub fn mapCluster(self: *Image, guest_offset: u64) !Mapping {
        if (guest_offset >= self.header.size) return error.OutOfRange;

        const cs = self.header.clusterSize();
        const l2_entries = self.header.l2Entries();
        const cluster_index = guest_offset / cs;
        const l2_index = cluster_index % l2_entries;
        const l1_index = cluster_index / l2_entries;

        if (l1_index >= self.l1.len) return error.OutOfRange;
        const l1_entry = self.l1[l1_index];
        const l2_offset = l1_entry & l1e_offset_mask;
        if (l2_offset == 0) return .unallocated;

        const ext_l2 = self.header.hasIncompatible(.extended_l2);
        const entry_size = self.header.l2EntrySize();

        // Read the single (8- or 16-byte) L2 entry we need.
        var entry_buf: [16]u8 = undefined;
        const at = l2_offset + l2_index * entry_size;
        const got = try self.file.readPositionalAll(self.io, entry_buf[0..entry_size], at);
        if (got != entry_size) return error.CorruptMapping;
        const l2_entry = std.mem.readInt(u64, entry_buf[0..8], .big);

        if ((l2_entry & l2e_compressed) != 0) {
            // Compressed cluster descriptor. Unaffected by Extended L2 (no
            // subclusters for compressed clusters).
            //   csize_shift = 62 - (cluster_bits - 8)
            //   csize_mask  = (1 << (cluster_bits - 8)) - 1
            //   offset_mask = (1 << csize_shift) - 1
            const csize_shift: u6 = @intCast(62 - (self.header.cluster_bits - 8));
            const csize_mask: u64 = (@as(u64, 1) << @intCast(self.header.cluster_bits - 8)) - 1;
            const offset_mask: u64 = (@as(u64, 1) << csize_shift) - 1;
            const coffset = l2_entry & offset_mask;
            const nb_csectors = ((l2_entry >> csize_shift) & csize_mask) + 1;
            const sector_size: u64 = 512;
            const csize = nb_csectors * sector_size - (coffset & (sector_size - 1));
            return .{ .compressed = .{ .coffset = coffset, .csize = @intCast(csize) } };
        }

        const host_offset = l2_entry & l2e_offset_mask;

        if (!ext_l2) {
            if ((l2_entry & standard_zero_bit) != 0) return .zero;
            if (host_offset == 0) return .unallocated;
            return .{ .standard = host_offset };
        }

        // Extended L2: bit 0 of the standard descriptor is unused (always
        // 0); subcluster status instead comes from the second 8-byte
        // allocation/zero bitmap.
        const bitmap = std.mem.readInt(u64, entry_buf[8..16], .big);
        const subcluster_size = self.header.subclusterSize();
        const subcluster_index: u6 = @intCast((guest_offset % cs) / subcluster_size);
        const alloc_bit = (bitmap >> subcluster_index) & 1;
        const zero_bit = (bitmap >> (32 + subcluster_index)) & 1;

        if (zero_bit != 0) return .zero;
        if (alloc_bit == 0) return .unallocated;
        if (host_offset == 0) return error.CorruptMapping; // allocated subcluster needs a valid offset
        return .{ .standard = host_offset + @as(u64, subcluster_index) * subcluster_size };
    }

    /// Decompress the single guest cluster described by `ref` into `dst`,
    /// which must be exactly one cluster in size. Any tail not produced by the
    /// decompressor is zero-filled.
    fn decompressCluster(self: *Image, ref: CompressedRef, dst: []u8) !void {
        const comp = try self.allocator.alloc(u8, ref.csize);
        defer self.allocator.free(comp);
        const got = try self.file.readPositionalAll(self.io, comp, ref.coffset);
        if (got != comp.len) return error.Truncated;

        var in: Io.Reader = .fixed(comp[0..got]);

        const produced = switch (self.header.compression_type) {
            0 => blk: {
                // Raw deflate (no zlib header). It stops at its end-of-block
                // marker, so streaming the remainder into a cluster-sized
                // writer is safe and ignores the trailing sector padding.
                var out: Io.Writer = .fixed(dst);
                var d: flate.Decompress = .init(&in, .raw, &.{});
                break :blk d.reader.streamRemaining(&out) catch |e| switch (e) {
                    error.WriteFailed => dst.len, // filled a whole cluster
                    else => return error.DecompressFailed,
                };
            },
            1 => blk: {
                // Indirect mode: give the decoder a window buffer sized to the
                // cluster, then read exactly one cluster out. We must NOT drain
                // the input, since qcow2 pads the payload to a sector boundary
                // and streamRemaining would misparse the trailing bytes as a
                // second zstd frame.
                const wlen: u32 = @intCast(@max(dst.len, 1));
                const zbuf = try self.allocator.alloc(u8, @as(usize, wlen) + zstd.block_size_max);
                defer self.allocator.free(zbuf);
                var d: zstd.Decompress = .init(&in, zbuf, .{ .window_len = wlen });
                break :blk d.reader.readSliceShort(dst) catch return error.DecompressFailed;
            },
            else => return error.UnsupportedCompressionType,
        };
        if (produced < dst.len) @memset(dst[produced..], 0);
    }

    /// Read `buf.len` bytes starting at `guest_offset` from the virtual disk.
    /// Unallocated and zero clusters read as zeros (backing files not yet
    /// followed). Compressed clusters are decoded in-place. For Extended L2
    /// images, standard/zero/unallocated status is resolved per-subcluster.
    pub fn read(self: *Image, guest_offset: u64, buf: []u8) !void {
        const cs = self.header.clusterSize();
        const ext_l2 = self.header.hasIncompatible(.extended_l2);
        const subcluster_size = if (ext_l2) self.header.subclusterSize() else cs;
        var pos: u64 = guest_offset;
        var written: usize = 0;
        while (written < buf.len) {
            if (pos >= self.header.size) return error.OutOfRange;
            const in_cluster = pos % cs;
            const mapping = try self.mapCluster(pos);

            // Compressed clusters have no subclusters, so they're always
            // resolved (and chunked) at full cluster granularity; everything
            // else is safe to chunk at subcluster granularity for Extended
            // L2 images (which is just the cluster size otherwise).
            const region = if (std.meta.activeTag(mapping) == .compressed) cs else subcluster_size;
            const in_region = pos % region;
            const chunk = @min(region - in_region, buf.len - written);
            const dst = buf[written .. written + chunk];

            switch (mapping) {
                .zero => @memset(dst, 0),
                .unallocated => try self.readBacking(pos, dst),
                .compressed => |ref| {
                    // Decompress the full cluster, then copy the requested slice.
                    const tmp = try self.allocator.alloc(u8, cs);
                    defer self.allocator.free(tmp);
                    try self.decompressCluster(ref, tmp);
                    @memcpy(dst, tmp[in_cluster .. in_cluster + chunk]);
                },
                .standard => |host_offset| {
                    const got = try self.file.readPositionalAll(
                        self.io,
                        dst,
                        host_offset + in_region,
                    );
                    if (got != dst.len) return error.Truncated;
                },
            }
            pos += chunk;
            written += chunk;
        }
    }

    /// Fill `dst` (covering guest range [pos, pos+dst.len)) from the backing
    /// image. Ranges with no backing file, or beyond the backing image's
    /// virtual size, read as zeros.
    fn readBacking(self: *Image, pos: u64, dst: []u8) anyerror!void {
        const backing = self.backing orelse {
            @memset(dst, 0);
            return;
        };
        if (pos >= backing.header.size) {
            @memset(dst, 0);
            return;
        }
        const avail = backing.header.size - pos;
        const from_backing: usize = @intCast(@min(@as(u64, dst.len), avail));
        try backing.read(pos, dst[0..from_backing]);
        if (from_backing < dst.len) @memset(dst[from_backing..], 0);
    }
};

/// Resolve a backing-file name against the directory of the parent image path.
/// Absolute names are returned as-is. Caller owns the returned slice.
fn resolveBackingPath(
    allocator: std.mem.Allocator,
    parent_path: []const u8,
    name: []const u8,
) ![]u8 {
    if (name.len > 0 and name[0] == '/') return allocator.dupe(u8, name);
    const dir = std.fs.path.dirname(parent_path) orelse return allocator.dupe(u8, name);
    return std.fs.path.join(allocator, &.{ dir, name });
}

fn rd32(buf: []const u8, off: usize) u32 {
    return std.mem.readInt(u32, buf[off..][0..4], .big);
}
fn rd64(buf: []const u8, off: usize) u64 {
    return std.mem.readInt(u64, buf[off..][0..8], .big);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

/// Test-only helper: write a minimal v3 header with the Extended L2
/// incompatible bit set into `buf[0..104]`.
const ExtL2HeaderOpts = struct {
    cluster_bits: u32,
    size: u64,
    l1_size: u32,
    l1_table_offset: u64,
    backing_file_offset: u64 = 0,
    backing_file_size: u32 = 0,
};
fn writeExtL2ImageHeader(buf: []u8, opts: ExtL2HeaderOpts) void {
    @memset(buf[0..104], 0);
    std.mem.writeInt(u32, buf[0..4], magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big); // version
    std.mem.writeInt(u64, buf[8..16], opts.backing_file_offset, .big);
    std.mem.writeInt(u32, buf[16..20], opts.backing_file_size, .big);
    std.mem.writeInt(u32, buf[20..24], opts.cluster_bits, .big);
    std.mem.writeInt(u64, buf[24..32], opts.size, .big);
    std.mem.writeInt(u32, buf[36..40], opts.l1_size, .big);
    std.mem.writeInt(u64, buf[40..48], opts.l1_table_offset, .big);
    std.mem.writeInt(u64, buf[72..80], @as(u64, 1) << 4, .big); // incompatible: extended_l2
    std.mem.writeInt(u32, buf[100..104], 104, .big); // header_length
}

test "parse minimal v3 header" {
    var buf: [104]u8 = @splat(0);
    std.mem.writeInt(u32, buf[0..4], magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big); // version
    std.mem.writeInt(u32, buf[20..24], 16, .big); // cluster_bits => 64KiB
    std.mem.writeInt(u64, buf[24..32], 64 * 1024 * 1024, .big); // size
    std.mem.writeInt(u32, buf[36..40], 1, .big); // l1_size
    std.mem.writeInt(u64, buf[40..48], 0x30000, .big); // l1_table_offset
    std.mem.writeInt(u32, buf[100..104], 104, .big); // header_length

    const h = try Header.parse(&buf);
    try std.testing.expectEqual(@as(u32, 3), h.version);
    try std.testing.expectEqual(@as(u64, 65536), h.clusterSize());
    try std.testing.expectEqual(@as(u64, 8192), h.l2Entries());
    try std.testing.expect(!h.hasIncompatible(.dirty));
}

test "parse compression_type field (zstd)" {
    var buf: [112]u8 = @splat(0);
    std.mem.writeInt(u32, buf[0..4], magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big);
    std.mem.writeInt(u32, buf[20..24], 16, .big);
    std.mem.writeInt(u64, buf[72..80], 1 << 3, .big); // incompatible: compression type bit
    std.mem.writeInt(u32, buf[100..104], 112, .big); // header_length includes byte 104
    buf[104] = 1; // compression_type = zstd
    const h = try Header.parse(&buf);
    try std.testing.expectEqual(@as(u8, 1), h.compression_type);
    try std.testing.expect(h.hasIncompatible(.compression_type));
}

test "reject bad magic" {
    var buf: [104]u8 = @splat(0);
    try std.testing.expectError(error.BadMagic, Header.parse(&buf));
}

test "reject unknown incompatible feature" {
    var buf: [104]u8 = @splat(0);
    std.mem.writeInt(u32, buf[0..4], magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big);
    std.mem.writeInt(u32, buf[20..24], 16, .big);
    std.mem.writeInt(u32, buf[100..104], 104, .big);
    std.mem.writeInt(u64, buf[72..80], @as(u64, 1) << 20, .big); // unknown bit
    try std.testing.expectError(error.UnknownIncompatibleFeature, Header.parse(&buf));
}

test "writer round-trip: create then read back" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    // Data spanning allocated + unallocated (zero) clusters.
    const vsize: u64 = 512 * 1024;
    const data = try a.alloc(u8, vsize);
    defer a.free(data);
    @memset(data, 0);
    for (data[0..1000], 0..) |*b, i| b.* = @intCast(i % 251); // first cluster
    for (data[300 * 1024 ..][0..2048], 0..) |*b, i| b.* = @intCast((i * 7) % 253);

    try writer.createFromRaw(a, io, tmp.dir, "rt.qcow2", data, vsize, .{});

    var img = try Image.open(a, io, tmp.dir, "rt.qcow2");
    defer img.close();
    try std.testing.expectEqual(vsize, img.header.size);

    const out = try a.alloc(u8, vsize);
    defer a.free(out);
    try img.read(0, out);
    try std.testing.expectEqualSlices(u8, data, out);
}

test "writer round-trip: extended L2 image, create then read back" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const vsize: u64 = 512 * 1024;
    const data = try a.alloc(u8, vsize);
    defer a.free(data);
    @memset(data, 0);
    for (data[0..1000], 0..) |*b, i| b.* = @intCast(i % 251); // first cluster
    for (data[300 * 1024 ..][0..2048], 0..) |*b, i| b.* = @intCast((i * 7) % 253);

    try writer.createFromRaw(a, io, tmp.dir, "ext-rt.qcow2", data, vsize, .{
        .cluster_bits = 14,
        .extended_l2 = true,
    });

    var img = try Image.open(a, io, tmp.dir, "ext-rt.qcow2");
    defer img.close();
    try std.testing.expectEqual(vsize, img.header.size);
    try std.testing.expect(img.header.hasIncompatible(.extended_l2));
    try std.testing.expectEqual(@as(u64, 16384 / 16), img.header.l2Entries());

    const out = try a.alloc(u8, vsize);
    defer a.free(out);
    try img.read(0, out);
    try std.testing.expectEqualSlices(u8, data, out);
}

test "writer: extended L2 requires cluster_bits >= 14" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const data = [_]u8{0} ** 16;
    try std.testing.expectError(error.BadClusterBits, writer.createFromRaw(
        a,
        io,
        tmp.dir,
        "bad.qcow2",
        &data,
        data.len,
        .{ .cluster_bits = 13, .extended_l2 = true },
    ));
}

test "reject extended L2 with cluster_bits < 14" {
    var buf: [104]u8 = @splat(0);
    std.mem.writeInt(u32, buf[0..4], magic, .big);
    std.mem.writeInt(u32, buf[4..8], 3, .big);
    std.mem.writeInt(u32, buf[20..24], 13, .big); // 8 KiB clusters: too small
    std.mem.writeInt(u32, buf[100..104], 104, .big);
    std.mem.writeInt(u64, buf[72..80], @as(u64, 1) << 4, .big); // extended_l2
    try std.testing.expectError(error.BadClusterBits, Header.parse(&buf));
}

test "extended L2: per-subcluster allocation and zero bitmap" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const cluster_bits: u32 = 14; // minimum allowed; 16 KiB clusters
    const cs: u64 = @as(u64, 1) << cluster_bits;
    const subcluster_size = cs / Header.subclusters_per_cluster; // 512 bytes

    // Layout: cluster 0 = header, 1 = L1 table, 2 = L2 table (extended),
    // 3 = the one allocated data cluster (shared by every allocated
    // subcluster; per-subcluster host offset = base + index*subcluster_size).
    const file = try a.alloc(u8, 4 * cs);
    defer a.free(file);
    @memset(file, 0);

    const l1_offset = 1 * cs;
    const l2_offset = 2 * cs;
    const data_offset = 3 * cs;

    writeExtL2ImageHeader(file[0..104], .{
        .cluster_bits = cluster_bits,
        .size = cs,
        .l1_size = 1,
        .l1_table_offset = l1_offset,
    });

    const copied: u64 = @as(u64, 1) << 63;
    std.mem.writeInt(u64, file[@intCast(l1_offset)..][0..8], l2_offset | copied, .big);

    // L2 entry 0 (16 bytes): first 8 = standard descriptor (host offset,
    // bit 0 unused for extended L2); last 8 = alloc bitmap (bits 0-31) |
    // zero bitmap (bits 32-63). Subcluster 0 and 3 allocated, subcluster 1
    // zero, everything else (including subcluster 2) unallocated.
    std.mem.writeInt(u64, file[@intCast(l2_offset)..][0..8], data_offset | copied, .big);
    const alloc_bits: u64 = (@as(u64, 1) << 0) | (@as(u64, 1) << 3);
    const zero_bits: u64 = @as(u64, 1) << (32 + 1);
    std.mem.writeInt(u64, file[@intCast(l2_offset + 8)..][0..8], alloc_bits | zero_bits, .big);

    // Recognizable pattern in the data cluster.
    for (file[@intCast(data_offset)..][0..cs], 0..) |*b, i| b.* = @intCast((i * 7 + 1) % 251);

    const out_file = try tmp.dir.createFile(io, "ext.qcow2", .{ .truncate = true });
    defer out_file.close(io);
    try out_file.writePositionalAll(io, file, 0);

    var img = try Image.open(a, io, tmp.dir, "ext.qcow2");
    defer img.close();

    // mapCluster resolves per-subcluster status directly.
    switch (try img.mapCluster(0)) {
        .standard => |h| try std.testing.expectEqual(data_offset, h),
        else => return error.TestUnexpectedResult,
    }
    switch (try img.mapCluster(1 * subcluster_size)) {
        .zero => {},
        else => return error.TestUnexpectedResult,
    }
    switch (try img.mapCluster(2 * subcluster_size)) {
        .unallocated => {},
        else => return error.TestUnexpectedResult,
    }
    switch (try img.mapCluster(3 * subcluster_size)) {
        .standard => |h| try std.testing.expectEqual(data_offset + 3 * subcluster_size, h),
        else => return error.TestUnexpectedResult,
    }

    // A whole-cluster read should splice together allocated / zero /
    // unallocated (no backing file => zero) subcluster ranges correctly.
    const got = try a.alloc(u8, cs);
    defer a.free(got);
    try img.read(0, got);

    const expected = try a.alloc(u8, cs);
    defer a.free(expected);
    @memset(expected, 0);
    for (expected[0..subcluster_size], 0..) |*b, i| b.* = @intCast((i * 7 + 1) % 251);
    for (expected[3 * subcluster_size ..][0..subcluster_size], 0..) |*b, i| {
        b.* = @intCast(((3 * subcluster_size + i) * 7 + 1) % 251);
    }
    try std.testing.expectEqualSlices(u8, expected, got);
}

test "extended L2: unallocated subclusters fall through to the backing file" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const cluster_bits: u32 = 14;
    const cs: u64 = @as(u64, 1) << cluster_bits;
    const subcluster_size = cs / Header.subclusters_per_cluster;
    const vsize = cs; // single guest cluster, matching the backing image size

    // Backing image: a plain (non-extended-L2) qcow2 with a known pattern.
    const backing_data = try a.alloc(u8, vsize);
    defer a.free(backing_data);
    for (backing_data, 0..) |*b, i| b.* = @intCast((i * 3 + 5) % 253);
    try writer.createFromRaw(a, io, tmp.dir, "backing.qcow2", backing_data, vsize, .{});

    // Main extended-L2 image referencing it.
    const file = try a.alloc(u8, 4 * cs);
    defer a.free(file);
    @memset(file, 0);

    const backing_name = "backing.qcow2";
    const backing_name_offset: u64 = 512; // clear of the 104-byte header
    @memcpy(file[@intCast(backing_name_offset)..][0..backing_name.len], backing_name);

    const l1_offset = 1 * cs;
    const l2_offset = 2 * cs;
    const data_offset = 3 * cs;

    writeExtL2ImageHeader(file[0..104], .{
        .cluster_bits = cluster_bits,
        .size = vsize,
        .l1_size = 1,
        .l1_table_offset = l1_offset,
        .backing_file_offset = backing_name_offset,
        .backing_file_size = @intCast(backing_name.len),
    });

    const copied: u64 = @as(u64, 1) << 63;
    std.mem.writeInt(u64, file[@intCast(l1_offset)..][0..8], l2_offset | copied, .big);

    // Only subcluster 0 (allocated) and subcluster 1 (zero) override the
    // backing file; every other subcluster is unallocated and must read
    // from the backing image.
    std.mem.writeInt(u64, file[@intCast(l2_offset)..][0..8], data_offset | copied, .big);
    const alloc_bits: u64 = @as(u64, 1) << 0;
    const zero_bits: u64 = @as(u64, 1) << (32 + 1);
    std.mem.writeInt(u64, file[@intCast(l2_offset + 8)..][0..8], alloc_bits | zero_bits, .big);

    for (file[@intCast(data_offset)..][0..cs], 0..) |*b, i| b.* = @intCast((i * 11 + 2) % 241);

    const out_file = try tmp.dir.createFile(io, "main.qcow2", .{ .truncate = true });
    defer out_file.close(io);
    try out_file.writePositionalAll(io, file, 0);

    var img = try Image.open(a, io, tmp.dir, "main.qcow2");
    defer img.close();
    try std.testing.expect(img.backing != null);

    const got = try a.alloc(u8, vsize);
    defer a.free(got);
    try img.read(0, got);

    const expected = try a.alloc(u8, vsize);
    defer a.free(expected);
    @memcpy(expected, backing_data); // default: everything comes from backing
    for (expected[0..subcluster_size], 0..) |*b, i| b.* = @intCast((i * 11 + 2) % 241);
    @memset(expected[subcluster_size .. 2 * subcluster_size], 0);
    try std.testing.expectEqualSlices(u8, expected, got);
}

test "extended L2: compressed cluster descriptor is unaffected by subclusters" {
    const io = std.testing.io;
    const a = std.testing.allocator;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const cluster_bits: u32 = 14;
    const cs: u64 = @as(u64, 1) << cluster_bits;

    const file = try a.alloc(u8, 3 * cs); // header, L1, L2 (no data cluster needed)
    defer a.free(file);
    @memset(file, 0);

    const l1_offset = 1 * cs;
    const l2_offset = 2 * cs;

    writeExtL2ImageHeader(file[0..104], .{
        .cluster_bits = cluster_bits,
        .size = cs,
        .l1_size = 1,
        .l1_table_offset = l1_offset,
    });

    const copied: u64 = @as(u64, 1) << 63;
    std.mem.writeInt(u64, file[@intCast(l1_offset)..][0..8], l2_offset | copied, .big);

    // Compressed cluster descriptor (bit 62 set); the trailing subcluster
    // bitmap word is reserved/unused for compressed clusters and must be
    // ignored, so fill it with garbage to make sure it isn't consulted.
    const csize_shift: u6 = 62 - (cluster_bits - 8);
    const coffset: u64 = 5000;
    const nb_extra_sectors: u64 = 2;
    const compressed_bit: u64 = @as(u64, 1) << 62;
    const first8 = compressed_bit | (nb_extra_sectors << csize_shift) | coffset;
    std.mem.writeInt(u64, file[@intCast(l2_offset)..][0..8], first8, .big);
    std.mem.writeInt(u64, file[@intCast(l2_offset + 8)..][0..8], 0xffffffffffffffff, .big);

    const out_file = try tmp.dir.createFile(io, "comp.qcow2", .{ .truncate = true });
    defer out_file.close(io);
    try out_file.writePositionalAll(io, file, 0);

    var img = try Image.open(a, io, tmp.dir, "comp.qcow2");
    defer img.close();

    switch (try img.mapCluster(0)) {
        .compressed => |ref| {
            try std.testing.expectEqual(@as(u64, 5000), ref.coffset);
            const expected_csize = (nb_extra_sectors + 1) * 512 - (coffset % 512);
            try std.testing.expectEqual(@as(u32, @intCast(expected_csize)), ref.csize);
        },
        else => return error.TestUnexpectedResult,
    }
}
