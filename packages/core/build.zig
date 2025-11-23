const std = @import("std");
const headers = @import("headers");
const compile_commands = @import("compile_commands");

pub fn build(b: *std.Build) void {
    // Config
    const target = b.standardTargetOptions(.{});

    const platform = @tagName(target.result.os.tag);
    const ext = switch (target.result.os.tag) {
        .macos => "mm",
        else => "cc",
    };
    const language = switch (target.result.os.tag) {
        .macos => std.Build.Module.CSourceLanguage.objective_cpp,
        else => std.Build.Module.CSourceLanguage.cpp,
    };
    const flags: []const []const u8 = &.{
        "-std=c++17",
    };

    // Dependencies
    const callback_dep = b.dependency("callback", .{});
    const headers_dep = b.dependency("headers", .{});

    // Modules
    const loop_mod = b.createModule(.{
        .root_source_file = b.path("src/loop/module.zig"),
    });
    const window_mod = b.createModule(.{
        .root_source_file = b.path("src/window/module.zig"),
        .imports = &.{
            .{ .name = "callback", .module = callback_dep.module("callback") },
            .{ .name = "loop", .module = loop_mod },
        },
    });

    const core_mod = b.addModule("core", .{
        .root_source_file = b.path("src/module.zig"),
        .imports = &.{
            .{ .name = "loop", .module = loop_mod },
            .{ .name = "window", .module = window_mod },
        },
    });

    // Platform Headers
    const src_root = b.path("src");
    const loop_headers = headers.generate(headers_dep.builder, .{
        .name = "loop",
        .root_source_file = loop_mod.root_source_file.?,
        .imports = headers.importsFromTable(b, loop_mod.import_table),
    });
    loop_mod.addIncludePath(loop_headers);
    loop_mod.addIncludePath(src_root);
    const window_headers = headers.generate(headers_dep.builder, .{
        .name = "window",
        .root_source_file = window_mod.root_source_file.?,
        .imports = headers.importsFromTable(b, window_mod.import_table),
    });
    window_mod.addIncludePath(window_headers);
    window_mod.addIncludePath(src_root);

    b.addNamedLazyPath("loop_headers", loop_headers);
    b.addNamedLazyPath("window_headers", window_headers);

    // Platform Implementations
    loop_mod.addCSourceFiles(.{
        .files = &.{
            b.fmt("./src/loop/platform/{s}/App.{s}", .{ platform, ext }),
        },
        .language = language,
        .flags = flags,
    });
    window_mod.addCSourceFiles(.{
        .files = &.{
            b.fmt("./src/window/platform/{s}/View.{s}", .{ platform, ext }),
            b.fmt("./src/window/platform/{s}/Window.{s}", .{ platform, ext }),
            b.fmt("./src/window/platform/{s}/WindowCallbacks.{s}", .{ platform, ext }),
        },
        .language = language,
        .flags = flags,
    });

    // Platform Libraries
    switch (target.result.os.tag) {
        .macos => {
            loop_mod.linkFramework("Cocoa", .{});
            loop_mod.linkFramework("AppKit", .{});
            window_mod.linkFramework("AppKit", .{});
        },
        else => {},
    }

    const cc_gen = compile_commands.generate(b, core_mod);
    b.default_step.dependOn(&cc_gen.step);

    // Example
    const example_step = b.step("example", "Run an example");
    example_step.dependOn(b.default_step);
    if (b.args) |args| {
        const example_name = args[0];
        const example_mod = b.createModule(.{
            .target = target,
            .optimize = .Debug,
            .root_source_file = b.path(b.fmt("examples/{s}.zig", .{example_name})),
        });
        example_mod.addImport("core", core_mod);
        const example_exe = b.addExecutable(.{
            .name = b.fmt("example_{s}", .{example_name}),
            .root_module = example_mod,
        });

        // const example_install = b.addInstallArtifact(example_exe, .{});
        // example_step.dependOn(&example_install.step);

        const example_run = b.addRunArtifact(example_exe);
        example_run.addArgs(args[1..]);
        example_step.dependOn(&example_run.step);
    }
}
