const std = @import("std");
const bundler = @import("bundle");

pub fn build(b: *std.Build) !void {
    _ = b; // stub
}

const UnvrsCore = struct {
    dep: *std.Build.Dependency,
    mod: *std.Build.Module,
};

const UnvrsWebview = struct {
    dep: *std.Build.Dependency,
    mod: *std.Build.Module,

    /// Link the context handlers to your main application module
    /// The webview context allows you to hook into callbacks run in sandboxed
    /// processes (such as during js initialization).
    pub fn link(self: UnvrsWebview, mod: *std.Build.Module) void {
        mod.linkLibrary(self.dep.artifact("webview"));
    }

    /// This bundles and automates copying all the WebView dependencies into a
    /// unvrs app bundle. This is especially handy on macos as it needs a lot
    /// of resource files in odd places.
    pub fn bundleAddon(self: UnvrsWebview, bun: bundler.Bundle) void {
        const webview = @import("webview");
        webview.bundleAddon(self.dep, bun);
    }
};

const Unvrs = struct {
    owner: *std.Build,
    dependency: *std.Build.Dependency,

    pub fn core(self: Unvrs, args: anytype) UnvrsCore {
        const dep = self.dependency.builder.dependency("core", args);
        const mod = dep.module("core");

        return .{
            .dep = dep,
            .mod = mod,
        };
    }

    pub fn webview(self: Unvrs, args: anytype) UnvrsWebview {
        const dep = self.dependency.builder.dependency("webview", args);
        const mod = dep.module("webview");

        return .{
            .dep = dep,
            .mod = mod,
        };
    }

    pub fn bundle(self: Unvrs, options: bundler.BundleOptions) bundler.Bundle {
        return bundler.pack(self.owner, options);
    }
};

/// Use the unvrs in your build process for making an application
pub fn use(b: *std.Build) *Unvrs {
    const unvrs = b.allocator.create(Unvrs) catch @panic("OOM");
    const unvrs_dep = b.dependency("unvrs", .{});

    unvrs.* = .{
        .owner = b,
        .dependency = unvrs_dep,
    };

    return unvrs;
}
