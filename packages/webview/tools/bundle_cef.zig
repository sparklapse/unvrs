const std = @import("std");
const bundle = @import("bundle");

const CEF_HELPER_VARIANTS: []const []const u8 = &.{
    "",
    "GPU",
    "Plugin",
    "Renderer",
};

pub fn bundleAddon(webview_dep: *std.Build.Dependency, bun: bundle.Bundle) void {
    const b = webview_dep.builder;

    switch (bun.platform) {
        .macos => |p| {
            const helper = webview_dep.artifact("cef_helper");
            const framework = webview_dep.namedLazyPath("cef_framework");

            p.addFramework("Chromium Embedded Framework.framework", framework);

            for (CEF_HELPER_VARIANTS) |variant| {
                const framework_name = if (variant.len > 0)
                    b.fmt("{s} Helper ({s}).app", .{bun.name, variant})
                else
                    b.fmt("{s} Helper.app", .{bun.name});

                const bundle_id = if (variant.len > 0)
                    b.fmt("{s}.helper.{s}", .{bun.id, variant})
                else
                    b.fmt("{s}.helper", .{bun.name});

                const bundle_name = if (variant.len > 0)
                    b.fmt("{s} Helper ({s})", .{bun.name, variant})
                else
                    b.fmt("{s} Helper", .{bun.name});

                const helper_bun = bundle.pack(webview_dep.builder, .{
                    .target = bun.target,
                    .exe = helper,
                    .id = bundle_id,
                    .name = bundle_name,
                });
                p.addFramework(framework_name, helper_bun.platform.macos.dist_wf.getDirectory());
            }
        },
        else => {},
    }
}
