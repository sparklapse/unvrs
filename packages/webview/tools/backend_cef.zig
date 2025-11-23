const std = @import("std");

pub const CefBackend = struct {
    target: std.Build.ResolvedTarget,
    headers: std.Build.LazyPath,
    wrapper_obj: std.Build.LazyPath,

    pub fn link(self: CefBackend, module: *std.Build.Module) void {
        module.addIncludePath(self.headers);
        module.addIncludePath(module.owner.path("src/backend/cef"));

        module.addCSourceFiles(.{
            .files = &.{
                "src/backend/cef/WebView.cc",
                "src/backend/cef/WebViewApp.cc",
                "src/backend/cef/WebViewHandler.cc",
            },
            .language = .cpp,
            .flags = &.{"-std=c++17"},
        });

        switch (self.target.result.os.tag) {
            .macos => {
                module.addCSourceFiles(.{
                    .files = &.{
                        "src/backend/cef/platform/macos/App.mm",
                        "src/backend/cef/platform/macos/WebViewApp.mm",
                        "src/backend/cef/platform/macos/WebViewHandler.mm",
                    },
                    .language = .objective_cpp,
                    .flags = &.{"-std=c++17"},
                });

                module.linkFramework("Cocoa", .{ .needed = true });
            },
            else => {},
        }

        module.addObjectFile(self.wrapper_obj);

        // TODO: Get this from the pipe output of PRINT_CEF_CONFIG from the cmake command
        module.addCMacro("__STDC_CONSTANT_MACROS", "1");
        module.addCMacro("__STDC_FORMAT_MACROS", "1");
        module.addCMacro("CEF_USE_SANDBOX", "1");
    }
};

pub fn build(b: *std.Build, target: std.Build.ResolvedTarget) CefBackend {
    const cef_dep_label = b.fmt(
        "cef_{s}_{s}",
        .{
            @tagName(target.result.os.tag),
            @tagName(target.result.cpu.arch),
        },
    );

    const cef_dep = b.dependency(cef_dep_label, .{});

    const cef_headers = b.addWriteFiles();
    _ = cef_headers.addCopyDirectory(cef_dep.path("include"), "include", .{});

    const cef_build: *CefWrapperBuild = .init(b, cef_dep.path(""), target);
    const cef_wrapper_obj = cef_build.wrapperObject();
    b.addNamedLazyPath(
        "cef_wrapper",
        cef_wrapper_obj,
    );

    const cef_backend: CefBackend = .{
        .target = target,
        .headers = cef_headers.getDirectory(),
        .wrapper_obj = cef_wrapper_obj,
    };

    switch (target.result.os.tag) {
        .macos => {
            const helper_mod = b.createModule(.{
                .target = target,
                .optimize = .ReleaseFast,
                .link_libcpp = true,
            });
            helper_mod.addCSourceFile(.{
                .file = b.path("src/backend/cef/platform/macos/helper.cc"),
                .flags = &.{
                    "-std=c++17",
                },
                .language = .cpp,
            });
            helper_mod.addObjectFile(cef_wrapper_obj);
            helper_mod.addIncludePath(cef_headers.getDirectory());

            // TODO: Get this from the pipe output of PRINT_CEF_CONFIG from the cmake command
            helper_mod.addCMacro("__STDC_CONSTANT_MACROS", "1");
            helper_mod.addCMacro("__STDC_FORMAT_MACROS", "1");
            helper_mod.addCMacro("CEF_USE_SANDBOX", "1");

            const helper_exe = b.addExecutable(.{
                .name = "cef_helper",
                .root_module = helper_mod,
            });

            b.installArtifact(helper_exe);

            const framework = cef_dep.path("Release/Chromium Embedded Framework.framework");
            b.addNamedLazyPath(
                "cef_framework",
                framework,
            );
            b.installDirectory(.{
                .source_dir = framework,
                .install_dir = .lib,
                .install_subdir = "Chromium Embedded Framework.framework",
            });
        },
        else => {},
    }

    return cef_backend;
}

const CefWrapperBuild = struct {
    step: std.Build.Step,
    target: std.Build.ResolvedTarget,
    source_dir: std.Build.LazyPath,
    build_dir: std.Build.LazyPath,
    wrapper_object: std.Build.GeneratedFile,

    pub fn init(b: *std.Build, source_dir: std.Build.LazyPath, target: std.Build.ResolvedTarget) *CefWrapperBuild {
        const self = b.allocator.create(CefWrapperBuild) catch @panic("OOM");

        const wf = b.addWriteFiles();
        const build_dir = wf.getDirectory();

        var step: std.Build.Step = .init(.{
            .id = .custom,
            .name = "cef",
            .owner = b,
            .makeFn = make,
        });
        step.dependOn(&wf.step);

        self.* = CefWrapperBuild{
            .step = step,
            .target = target,
            .source_dir = source_dir,
            .build_dir = build_dir,
            .wrapper_object = .{ .step = &self.step },
        };

        return self;
    }

    pub fn wrapperObject(self: *CefWrapperBuild) std.Build.LazyPath {
        return .{
            .generated = .{
                .file = &self.wrapper_object,
            },
        };
    }

    pub fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        _ = options;
        const cef: *CefWrapperBuild = @fieldParentPtr("step", step);

        try cef.buildWrapper();
    }

    fn buildWrapper(self: *CefWrapperBuild) !void {
        const b = self.step.owner;
        const source_dir = self.source_dir.getPath3(self.step.owner, &self.step);
        const build_dir = self.build_dir.getPath3(self.step.owner, &self.step);

        // Create a CMakeLists.txt for building just the libcef_dll_wrapper
        const cmake_content =
            \\cmake_minimum_required(VERSION 3.21)
            \\project(cef_wrapper)
            \\
            \\set(CMAKE_CXX_STANDARD 17)
            \\set(CMAKE_CXX_STANDARD_REQUIRED ON)
            \\set(CMAKE_CONFIGURATION_TYPES Debug Release)
            \\
            \\set(CEF_ROOT "{s}")
            \\include_directories(${{CEF_ROOT}})
            \\
            \\list(
            \\    APPEND
            \\    CMAKE_MODULE_PATH
            \\    "${{CEF_ROOT}}/cmake"
            \\)
            \\find_package(CEF REQUIRED)
            \\add_subdirectory(${{CEF_LIBCEF_DLL_WRAPPER_PATH}} libcef_dll_wrapper)
            \\PRINT_CEF_CONFIG()
            \\
        ;

        // Write CMakeLists.txt to build directory
        const cef_source_str = try source_dir.toString(b.allocator);
        const cmake_content_formatted = try std.fmt.allocPrint(b.allocator, cmake_content, .{cef_source_str});

        const build_dir_str = try build_dir.toString(b.allocator);
        const cmake_file_path = try std.fs.path.join(b.allocator, &[_][]const u8{ build_dir_str, "CMakeLists.txt" });
        try std.fs.cwd().writeFile(.{ .sub_path = cmake_file_path, .data = cmake_content_formatted });

        var cmake_configure = std.process.Child.init(&[_][]const u8{
            "cmake",
            "-S",
            ".",
            "-B",
            "cef_build",
            "-DCMAKE_BUILD_TYPE=Debug", // TODO: Swap this between Debug and release based on zig
        }, b.allocator);
        cmake_configure.cwd = build_dir_str;
        cmake_configure.stdout_behavior = .Ignore;
        _ = try cmake_configure.spawnAndWait();

        var cmake_build = std.process.Child.init(&[_][]const u8{
            "cmake",
            "--build",
            "cef_build",
            "--target",
            "libcef_dll_wrapper",
        }, b.allocator);
        cmake_build.cwd = build_dir_str;
        cmake_build.stdout_behavior = .Ignore;
        _ = try cmake_build.spawnAndWait();

        self.wrapper_object.path = self
            .build_dir
            .path(b, "cef_build/libcef_dll_wrapper/libcef_dll_wrapper.a")
            .getPath3(b, &self.step)
            .toString(b.allocator) catch @panic("OOM");
    }
};
