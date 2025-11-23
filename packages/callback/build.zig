const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library Module
    const callback_mod = b.addModule("callback", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/module.zig"),
    });

    // Tests
    const test_step = b.step("test", "Run unit tests");
    const tests_mod = b.createModule(.{
        .root_source_file = b.path("tests/test.zig"),
        .target = target,
        .optimize = .Debug,
        .link_libc = true,
    });
    tests_mod.addCSourceFile(.{
        .file = b.path("tests/test.c"),
        .language = .c,
    });
    tests_mod.addImport("callback", callback_mod);
    const tests = b.addTest(.{
        .root_module = tests_mod,
    });
    const run_unit_tests = b.addRunArtifact(tests);

    test_step.dependOn(&run_unit_tests.step);
}
