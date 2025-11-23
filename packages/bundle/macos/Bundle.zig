const std = @import("std");
const BundleOptions = @import("../BundleOptions.zig");

const Bundle = @This();

const info_plist_template = @embedFile("./Info.plist");

step: std.Build.Step,
bundle_options: BundleOptions,
dist_wf: *std.Build.Step.WriteFile,

pub fn init(b: *std.Build, bundle_options: BundleOptions) *Bundle {
    const self = b.allocator.create(Bundle) catch @panic("OOM");

    var step: std.Build.Step = .init(.{
        .id = .custom,
        .name = "bundle_macos",
        .owner = b,
    });

    const dist_wf = b.addWriteFiles();
    step.dependOn(&dist_wf.step);

    _ = dist_wf.addCopyFile(
        bundle_options.exe.getEmittedBin(),
        b.fmt("Contents/MacOS/{s}", .{bundle_options.name}),
    );
    _ = dist_wf.add("Contents/Info.plist", b.fmt(info_plist_template, .{
        bundle_options.name,
        bundle_options.id,
        bundle_options.name,
    }));

    self.* = Bundle{
        .step = step,
        .bundle_options = bundle_options,
        .dist_wf = dist_wf,
    };

    return self;
}

/// Add something into the 'Frameworks' directory
pub fn addFramework(self: *Bundle, name: []const u8, source: std.Build.LazyPath) void {
    const b = self.step.owner;
    _ = self.dist_wf.addCopyDirectory(
        source,
        b.fmt("Contents/Frameworks/{s}", .{name}),
        .{},
    );
}
