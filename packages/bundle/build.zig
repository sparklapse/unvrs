const std = @import("std");
const MacOSBundle = @import("./macos/Bundle.zig");

pub const BundleOptions = @import("./BundleOptions.zig");

pub fn build(b: *std.Build) void {
    _ = b; // stub
}

pub const Bundle = struct {
    owner: *std.Build,
    target: std.Build.ResolvedTarget,
    platform: union(enum) {
        unknown: void,
        macos: *MacOSBundle,
    },
    id: []const u8,
    name: []const u8,

    pub fn install(self: Bundle) void {
        switch (self.platform) {
            .macos => |p| {
                const inst = self.owner.addInstallDirectory(.{
                    .source_dir = p.dist_wf.getDirectory(),
                    .install_dir = .prefix,
                    .install_subdir = "app/unvrs.app",
                });
                self.owner.getInstallStep().dependOn(&inst.step);
            },
            .unknown => {
                self.owner.getInstallStep().dependOn(
                    &self.owner.addFail("Platform doesn't support bundling").step,
                );
            },
        }
    }
};

pub fn pack(b: *std.Build, options: BundleOptions) Bundle {
    switch (options.target.result.os.tag) {
        .macos => {
            const bundle: *MacOSBundle = .init(b, options);
            b.getInstallStep().dependOn(&bundle.step);

            return .{
                .owner = b,
                .target = options.target,
                .platform = .{ .macos = bundle },
                .id = options.id,
                .name = options.name,
            };
        },
        else => {
            const message = b.fmt(
                "Cannot pack bundle for taget '{s}'",
                .{@tagName(options.target.result.os.tag)},
            );
            b.getInstallStep().dependOn(&b.addFail(message).step);
        },
    }

    return .{
        .owner = b,
        .target = options.target,
        .platform = .{ .unknown = {} },
        .id = options.id,
        .name = options.name,
    };
}
