const std = @import("std");

pub fn onContextInit() void {
    std.debug.print("Context init", .{});
}
