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
    context_mod: *std.Build.Module,

    pub fn linkContext(self: UnvrsWebview, mod: *std.Build.Module) void {
        mod.linkLibrary(self.dep.artifact("webview_context"));
    }

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
        const context_mod = dep.module("webview_context");

        return .{
            .dep = dep,
            .mod = mod,
            .context_mod = context_mod,
        };
    }

    pub fn bundle(self: Unvrs, options: bundler.BundleOptions) bundler.Bundle {
        return bundler.pack(self.owner, options);
    }
};

pub fn use(b: *std.Build) *Unvrs {
    const unvrs = b.allocator.create(Unvrs) catch @panic("OOM");
    const unvrs_dep = b.dependency("unvrs", .{});

    unvrs.* = .{
        .owner = b,
        .dependency = unvrs_dep,
    };

    return unvrs;
}
