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

    // Dependencies
    const core_dep = b.dependency("core", .{});
    const headers_dep = b.dependency("headers", .{});

    // Context binding
    const context_root_opt = b.option(std.Build.LazyPath, "context_root", "a custom context to use for the web engine") orelse b.path("src/context/default_context.zig");

    const context_mod = b.addModule("webview_context", .{
        .root_source_file = context_root_opt,
    });

    const context_lib_mod = b.createModule(.{
        .root_source_file = b.path("src/context/module.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "context", .module = context_mod },
        },
    });

    const context_lib = b.addLibrary(.{
        .name = "webview_context",
        .root_module = context_lib_mod,
        .linkage = .static,
    });

    b.installArtifact(context_lib);

    // WebView Module
    const webview_mod = b.addModule("webview", .{
        .root_source_file = b.path("src/module.zig"),
        .imports = &.{
            .{ .name = "core", .module = core_dep.module("core") },
            .{ .name = "context_binding", .module = context_lib_mod },
        },
        .link_libcpp = true,
    });

    const webview_headers = headers.generate(headers_dep.builder, .{
        .name = "webview",
        .root_source_file = webview_mod.root_source_file.?,
        .imports = headers.importsFromTable(b, webview_mod.import_table),
    });

    webview_mod.addIncludePath(webview_headers);
    webview_mod.addIncludePath(b.path("src"));
    webview_mod.addIncludePath(core_dep.path("src"));

    // Backend config
    const backend_opt = b.option(Backend, "backend", "what browser backend to use") orelse .cef;
    const backend = switch (backend_opt) {
        .cef => cef_backend.build(b, .{
            .target = target,
            .context_lib = context_lib,
            .webview_headers = webview_headers,
        }),
        .webkit => @panic("Not implemented"),
    };
    backend.link(webview_mod, .{});

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
