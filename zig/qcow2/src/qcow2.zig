//! Native Zig qcow2 image reader.
//!
//! A dependency-free, clean-room implementation of the qcow2 on-disk format
//! (see `docs/interop/qcow2.rst` in the QEMU tree). No QEMU C code is used.
//!
//! Current scope: read path for v2/v3 images with standard, zero, and
//! unallocated clusters. Compressed clusters and backing-file chains are
//! detected and surfaced as explicit errors (implementation in progress).
//!
//! All multi-byte integers in qcow2 are stored big-endian.

const std = @import("std");
const Io = std.Io;
const flate = std.compress.flate;
const zstd = std.compress.zstd;

pub const magic: u32 = 0x514649fb; // "QFI\xfb"

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

    pub fn clusterSize(self: Header) u64 {
        return @as(u64, 1) << @intCast(self.cluster_bits);
    }

    /// Number of standard (8-byte) L2 entries per L2 table cluster.
    pub fn l2Entries(self: Header) u64 {
        return self.clusterSize() / @sizeOf(u64);
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
    UnsupportedExtendedL2,
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

    /// Resolve the mapping for the guest cluster containing `guest_offset`.
    pub fn mapCluster(self: *Image, guest_offset: u64) !Mapping {
        if (guest_offset >= self.header.size) return error.OutOfRange;
        if (self.header.hasIncompatible(.extended_l2)) return error.UnsupportedExtendedL2;

        const cs = self.header.clusterSize();
        const l2_entries = self.header.l2Entries();
        const cluster_index = guest_offset / cs;
        const l2_index = cluster_index % l2_entries;
        const l1_index = cluster_index / l2_entries;

        if (l1_index >= self.l1.len) return error.OutOfRange;
        const l1_entry = self.l1[l1_index];
        const l2_offset = l1_entry & l1e_offset_mask;
        if (l2_offset == 0) return .unallocated;

        // Read the single L2 entry we need.
        var entry_buf: [8]u8 = undefined;
        const at = l2_offset + l2_index * @sizeOf(u64);
        const got = try self.file.readPositionalAll(self.io, &entry_buf, at);
        if (got != entry_buf.len) return error.CorruptMapping;
        const l2_entry = std.mem.readInt(u64, &entry_buf, .big);

        if ((l2_entry & l2e_compressed) != 0) {
            // Compressed cluster descriptor.
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
        if ((l2_entry & standard_zero_bit) != 0) return .zero;
        if (host_offset == 0) return .unallocated;
        return .{ .standard = host_offset };
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
    /// followed). Compressed clusters are decoded in-place.
    pub fn read(self: *Image, guest_offset: u64, buf: []u8) !void {
        const cs = self.header.clusterSize();
        var pos: u64 = guest_offset;
        var written: usize = 0;
        while (written < buf.len) {
            if (pos >= self.header.size) return error.OutOfRange;
            const in_cluster = pos % cs;
            const chunk = @min(cs - in_cluster, buf.len - written);
            const dst = buf[written .. written + chunk];

            switch (try self.mapCluster(pos)) {
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
                        host_offset + in_cluster,
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
