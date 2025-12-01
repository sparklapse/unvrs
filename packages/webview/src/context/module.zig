const std = @import("std");
// const context = @import("context");

pub export fn u_onContextInit() callconv(.c) void {
    std.debug.print("Hello context\n", .{});
}
