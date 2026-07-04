const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // The reusable nbd module, importable by consumers as `@import("nbd")`.
    const mod = b.addModule("nbd", .{
        .root_source_file = b.path("src/nbd.zig"),
        .target = target,
    });

    // The `nbd` CLI tool.
    const exe = b.addExecutable(.{
        .name = "nbd",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "nbd", .module = mod },
            },
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the nbd CLI");
    run_step.dependOn(&run_cmd.step);

    // Tests.
    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    // `src/server.zig`'s tests aren't reachable from `src/nbd.zig` as a
    // *test* root (Zig only auto-discovers `test` blocks declared in the
    // module's own root file), even though `nbd.zig` re-exports it as
    // `nbd.server`, so it needs its own test root too.
    const server_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/server.zig"),
        .target = target,
    }) });
    const run_server_tests = b.addRunArtifact(server_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_server_tests.step);
}
