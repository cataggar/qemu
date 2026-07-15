// SPDX-License-Identifier: GPL-2.0-or-later

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const is_windows = target.result.os.tag == .windows;
    const is_musl = target.result.abi == .musl;
    const dep_options = .{
        .target = target,
        .optimize = optimize,
    };

    const glib = b.dependency("glib", dep_options);
    const libslirp = b.dependency("libslirp", dep_options);
    const pixman = b.dependency("pixman", dep_options);
    const zlib = b.dependency("zlib", dep_options);
    const zstd = b.dependency("zstd", .{
        .target = target,
        .optimize = optimize,
        .tools = false,
        .multithread = false,
    });
    const nettle = b.dependency("nettle", dep_options);
    const libfdt = b.dependency("libfdt", dep_options);
    const gettext = b.dependency("gettext", .{});
    const libiconv = b.dependency("libiconv", .{});

    b.installArtifact(glib.artifact("glib-2.0"));
    if (is_musl or is_windows)
        b.installArtifact(glib.artifact("intl"));
    if (is_windows)
        b.installArtifact(glib.artifact("iconv"));
    b.installArtifact(libslirp.artifact("slirp"));
    b.installArtifact(pixman.artifact("pixman-1"));
    b.installArtifact(zlib.artifact("z"));
    b.installArtifact(zstd.artifact("zstd"));
    b.installArtifact(nettle.artifact("nettle"));
    b.installArtifact(libfdt.artifact("fdt"));

    const glib_libs = if (is_windows)
        "-L${libdir} -lglib-2.0 -liconv -lintl -lws2_32 -lwinmm -lole32 -lshell32"
    else if (is_musl)
        "-L${libdir} -lglib-2.0 -lintl -pthread -lm"
    else
        "-L${libdir} -lglib-2.0 -pthread -lm";
    const slirp_libs = if (is_windows)
        "-L${libdir} -lslirp -lglib-2.0 -liconv -lintl -lws2_32 -lwinmm -lole32 -lshell32 -liphlpapi"
    else if (is_musl)
        "-L${libdir} -lslirp -lglib-2.0 -lintl -pthread -lm"
    else
        "-L${libdir} -lslirp -lglib-2.0 -pthread -lm";

    const pc_files = b.addWriteFiles();
    installPkgConfig(b, pc_files, .{
        .file = "glib-2.0.pc",
        .name = "GLib",
        .description = "Core application building blocks",
        .version = "2.89.1",
        .cflags = "-I${includedir} -I${includedir}/glib",
        .libs = glib_libs,
    });
    installPkgConfig(b, pc_files, .{
        .file = "slirp.pc",
        .name = "libslirp",
        .description = "User-mode networking library",
        .version = "4.9.3",
        .cflags = "-I${includedir}/slirp -DLIBSLIRP_STATIC",
        .libs = slirp_libs,
    });
    installPkgConfig(b, pc_files, .{
        .file = "pixman-1.pc",
        .name = "Pixman",
        .description = "The pixman library",
        .version = "0.46.5",
        .cflags = "-I${includedir}/pixman-1",
        .libs = "-L${libdir} -lpixman-1 -lm",
    });
    installPkgConfig(b, pc_files, .{
        .file = "zlib.pc",
        .name = "zlib",
        .description = "zlib compression library",
        .version = "1.3.2",
        .cflags = "-I${includedir}",
        .libs = "-L${libdir} -lz",
    });
    installPkgConfig(b, pc_files, .{
        .file = "libzstd.pc",
        .name = "libzstd",
        .description = "Zstandard compression library",
        .version = "1.6.0",
        .cflags = "-I${includedir}",
        .libs = "-L${libdir} -lzstd",
    });
    installPkgConfig(b, pc_files, .{
        .file = "nettle.pc",
        .name = "Nettle",
        .description = "Low-level cryptographic library",
        .version = "4.0",
        .cflags = "-I${includedir}",
        .libs = "-L${libdir} -lnettle",
    });
    installPkgConfig(b, pc_files, .{
        .file = "libfdt.pc",
        .name = "libfdt",
        .description = "Flat Device Tree manipulation",
        .version = "1.8.1",
        .cflags = "-I${includedir}",
        .libs = "-L${libdir} -lfdt",
    });

    installLicense(b, glib.path("LICENSES/LGPL-2.1-or-later.txt"), "glib/LGPL-2.1-or-later.txt");
    installLicense(b, libslirp.path("COPYRIGHT"), "libslirp/COPYRIGHT");
    installLicense(b, pixman.path("COPYING"), "pixman/COPYING");
    installLicense(b, zlib.path("LICENSE"), "zlib/LICENSE");
    installLicense(b, zstd.path("LICENSE"), "zstd/LICENSE");
    installLicense(b, nettle.path("COPYING.LESSERv3"), "nettle/COPYING.LESSERv3");
    installLicense(b, nettle.path("COPYINGv2"), "nettle/COPYINGv2");
    installLicense(b, libfdt.path("BSD-2-Clause"), "libfdt/BSD-2-Clause");
    installLicense(b, gettext.path("COPYING"), "gettext/COPYING");
    installLicense(b, libiconv.path("COPYING.LIB"), "libiconv/COPYING.LIB");

    const deps_step = b.step("deps", "Build and install QEMU target dependencies");
    deps_step.dependOn(b.getInstallStep());
}

const PkgConfig = struct {
    file: []const u8,
    name: []const u8,
    description: []const u8,
    version: []const u8,
    cflags: []const u8,
    libs: []const u8,
};

fn installPkgConfig(b: *std.Build, files: *std.Build.Step.WriteFile, pc: PkgConfig) void {
    const source = files.add(pc.file, b.fmt(
        \\prefix=${{pcfiledir}}/../..
        \\exec_prefix=${{prefix}}
        \\libdir=${{prefix}}/lib
        \\includedir=${{prefix}}/include
        \\bindir=${{prefix}}/bin
        \\
        \\Name: {s}
        \\Description: {s}
        \\Version: {s}
        \\Cflags: {s}
        \\Libs: {s}
        \\
    , .{
        pc.name,
        pc.description,
        pc.version,
        pc.cflags,
        pc.libs,
    }));
    const install = b.addInstallFileWithDir(
        source,
        .lib,
        b.fmt("pkgconfig/{s}", .{pc.file}),
    );
    b.getInstallStep().dependOn(&install.step);
}

fn installLicense(b: *std.Build, source: std.Build.LazyPath, destination: []const u8) void {
    const install = b.addInstallFileWithDir(
        source,
        .{ .custom = "share/licenses/qemu-deps" },
        destination,
    );
    b.getInstallStep().dependOn(&install.step);
}
