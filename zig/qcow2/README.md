# qcow2 — native Zig qcow2 reader

A dependency-free, clean-room implementation of the [qcow2](../../docs/interop/qcow2.rst)
disk image format in Zig. No QEMU C code, no libvirt, no external dependencies —
just `@import("qcow2")` in your `build.zig`.

Part of the Zig-on-QEMU experiment (see issue #2). MIT licensed.

## Status

- [x] Header parsing (v2 / v3), feature-bit validation
- [x] L1/L2 cluster mapping (standard / zero / unallocated / compressed)
- [x] `read(guest_offset, buf)` for uncompressed images
- [x] Compressed clusters (deflate / zstd)
- [x] `info` / `map` / `read` CLI
- [x] Backing-file chains
- [ ] Extended L2 (subcluster) entries
- [x] Writer / image creation (`convert` raw → qcow2)

## Build & test

Requires Zig 0.16.

```sh
zig build test        # run unit tests
zig build             # build the CLI into zig-out/bin/qcow2
zig build run -- info disk.qcow2
```

## CLI

```
qcow2 info <image>                 dump header + feature summary
qcow2 map  <image> <offset>        classify the cluster at a guest offset
qcow2 read <image> <offset> <len>  write raw guest bytes to stdout
qcow2 convert <raw_in> <qcow2_out> create a qcow2 image from a raw file
```

## Validation against qemu-img

The reader is cross-checked against the `qemu-img` binary built from this tree
with `zig cc` (the `zig16` branch). For example:

```sh
# create a qcow2, write a known pattern via a raw round-trip
qemu-img create -f qcow2 disk.qcow2 64M
# ... populate, then compare:
qcow2 read disk.qcow2 0 4096 | cmp - <(qemu-img dd ... )
```

## Library usage

```zig
const qcow2 = @import("qcow2");

var img = try qcow2.Image.open(allocator, io, std.Io.Dir.cwd(), "disk.qcow2");
defer img.close();

var buf: [4096]u8 = undefined;
try img.read(0, &buf);
```
