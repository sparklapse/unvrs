const std = @import("std");
const bundle = @import("bundle");
const webview = @import("webview");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const core_dep = b.dependency("core", .{});
    const webview_dep = b.dependency("webview", .{});

    const prog_mod = b.createModule(.{
        .target = target,
        .root_source_file = b.path("src/main.zig"),
        .imports = &.{
            .{ .name = "core", .module = core_dep.module("core") },
            .{ .name = "webview", .module = webview_dep.module("webview") },
        },
    });

    const prog_exe = b.addExecutable(.{
        .name = "example",
        .root_module = prog_mod,
    });

    const prog_bun = bundle.pack(b, .{
        .target = target,
        .exe = prog_exe,
    });
    webview.bundleHelper(prog_bun, webview_dep);

    prog_bun.install(b);
}
