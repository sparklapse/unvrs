const std = @import("std");
pub const types = @import("context_types");

pub fn getCachePath() []const u8 {
    return "./wvcache";
}

pub fn onContextInit() void {}

pub fn onContextCreate(js_ctx: *types.JSContext) void {
    _ = js_ctx;
}
