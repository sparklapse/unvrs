const std = @import("std");
const headers = @import("headers");
const compile_commands = @import("compile_commands");
const bundle = @import("bundle");

const cef_backend = @import("./tools/backend_cef.zig");
const cef_bundler = @import("./tools/bundle_cef.zig");

pub const Backend = enum {
    /// Available on windows, macos, linux
    cef,
    /// Available on macos, ios
    webkit,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const core_dep = b.dependency("core", .{});
    const headers_dep = b.dependency("headers", .{});

    // Context binding
    const context_types_mod = b.createModule(.{
        .root_source_file = b.path("src/context/types.zig"),
    });

    const user_context_root_opt = b.option(std.Build.LazyPath, "context_root", "a custom context to use for the web engine") orelse b.path("src/context/templates/no_context.zig");

    const user_context_mod = b.addModule("webview_user_context", .{
        .root_source_file = user_context_root_opt,
        .imports = &.{
            .{ .name = "types", .module = context_types_mod },
        },
    });

    // WebView Module
    const webview_mod = b.addModule("webview", .{
        .root_source_file = b.path("src/module.zig"),
        .imports = &.{
            .{ .name = "core", .module = core_dep.module("core") },
            .{ .name = "context_types", .module = context_types_mod },
            .{ .name = "user_context", .module = user_context_mod },
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
        // We have to copy and alter the imports since user context could do
        // some weird things that break header compilation
        .imports = &.{
            .{ .name = "core", .module = core_dep.module("core") },
            .{ .name = "context_types", .module = context_types_mod },
            .{ .name = "user_context", .module = b.createModule(.{
                .root_source_file = b.path("src/context/templates/no_context.zig"),
            }) },
        },
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
    const backend_opt = b.option(Backend, "backend", "what browser backend to use") orelse .cef;
    _ = switch (backend_opt) {
        .cef => cef_backend.build(b, .{
            .target = target,
            .optimize = optimize,
            .webview_lib = webview_lib,
            .webview_mod = webview_mod,
            .webview_headers = webview_headers,
        }),
        .webkit => @panic("Not implemented"),
    };

    // Compile commands
    const cc_gen = compile_commands.generate(b, webview_mod);
    b.default_step.dependOn(&cc_gen.step);
}

pub fn bundleAddon(webview_dep: *std.Build.Dependency, bun: bundle.Bundle) void {
    const backend_arg = if (webview_dep.builder.user_input_options.get("backend")) |opt| std.meta.stringToEnum(Backend, opt.value.scalar) else null;
    const backend_opt: Backend = backend_arg orelse .cef;

    switch (backend_opt) {
        .cef => cef_bundler.bundleAddon(webview_dep, bun),
        .webkit => @panic("Not implemented"),
    }
}
