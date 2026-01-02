const std = @import("std");
const headers = @import("headers");
const compile_commands = @import("compile_commands");
const bundle = @import("bundle");

pub const Backend = enum {
    /// Available on macos, ios
    webkit,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const core_dep = b.dependency("core", .{});
    const callback_dep = b.dependency("callback", .{});
    const headers_dep = b.dependency("headers", .{});

    // WebView Module
    const webview_mod = b.addModule("webview", .{
        .root_source_file = b.path("src/module.zig"),
        .imports = &.{
            .{ .name = "core", .module = core_dep.module("core") },
            .{ .name = "callback", .module = callback_dep.module("callback") },
        },
        .link_libcpp = true,
        .target = target,
        .optimize = optimize,
    });

    const webview_lib = b.addLibrary(.{
        .name = "webview",
        .root_module = webview_mod,
        .linkage = .static,
    });

    b.installArtifact(webview_lib);

    const webview_headers = headers.generate(headers_dep.builder, .{
        .name = "webview",
        .root_source_file = webview_mod.root_source_file.?,
        .imports = headers.importsFromTable(b, webview_mod.import_table),
    });

    webview_mod.addIncludePath(webview_headers);
    webview_mod.addIncludePath(b.path("src"));
    webview_mod.addIncludePath(core_dep.path("src"));

    const webview_headers_inst = b.addInstallDirectory(.{
        .source_dir = webview_headers,
        .install_dir = .header,
        .install_subdir = "",
    });
    b.getInstallStep().dependOn(&webview_headers_inst.step);

    // Backend config
    const backend_opt = b.option(Backend, "backend", "what browser backend to use") orelse .webkit;
    _ = switch (backend_opt) {
        .webkit => {
            switch (target.result.os.tag) {
                .macos, .ios, .visionos => {},
                else => {
                    b.default_step.dependOn(&b.addFail("Platform does not support webkit").step);
                },
            }
            webview_mod.linkFramework("WebKit", .{ .needed = true });
            webview_mod.addCSourceFiles(.{
                .files = &.{
                    "src/backend/webkit/WebView.mm"
                },
            });
        },
    };

    // Compile commands
    const cc_gen = compile_commands.generate(b, webview_mod);
    b.default_step.dependOn(&cc_gen.step);
}

pub fn bundleAddon(webview_dep: *std.Build.Dependency, bun: bundle.Bundle) void {
    _ = bun;
    const backend_arg = if (webview_dep.builder.user_input_options.get("backend")) |opt| std.meta.stringToEnum(Backend, opt.value.scalar) else null;
    const backend_opt: Backend = backend_arg orelse .webkit;

    switch (backend_opt) {
        .webkit => {
            // No bundle needed
        },
    }
}
