const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // The reusable qmp module, importable by consumers as `@import("qmp")`.
    const mod = b.addModule("qmp", .{
        .root_source_file = b.path("src/qmp.zig"),
        .target = target,
    });

    // The `qmp` CLI tool.
    const exe = b.addExecutable(.{
        .name = "qmp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "qmp", .module = mod },
            },
        }),
    });
    b.installArtifact(exe);

    // Offline QAPI-schema-to-Zig-bindings generator (issue #3 stretch goal).
    // Not part of the default build graph's dependency chain on qapi/*.json;
    // run manually against a QEMU checkout (see README.md) and commit the
    // generated src/qapi_generated.zig.
    const codegen_exe = b.addExecutable(.{
        .name = "qapi-codegen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/qapi_codegen.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(codegen_exe);

    const run_codegen = b.addRunArtifact(codegen_exe);
    run_codegen.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_codegen.addArgs(args);
    const codegen_step = b.step("qapi-codegen", "Regenerate src/qapi_generated.zig from a QEMU checkout's qapi/qapi-schema.json");
    codegen_step.dependOn(&run_codegen.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Run the qmp CLI");
    run_step.dependOn(&run_cmd.step);

    // Tests.
    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const codegen_tests = b.addTest(.{ .root_module = codegen_exe.root_module });
    const run_codegen_tests = b.addRunArtifact(codegen_tests);
    // `tools/qapi_schema.zig`'s tests aren't reachable from `qapi_codegen.zig`
    // as a *test* root (Zig only auto-discovers `test` blocks declared in
    // the module's own root file), so it needs its own test root too.
    const schema_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("tools/qapi_schema.zig"),
        .target = target,
    }) });
    const run_schema_tests = b.addRunArtifact(schema_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
    test_step.dependOn(&run_codegen_tests.step);
    test_step.dependOn(&run_schema_tests.step);
}
