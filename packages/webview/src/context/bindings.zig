const std = @import("std");

const types = @import("context_types");
const context = @import("user_context");
const default = @import("./templates/default_context.zig");

/// Small helper function to get a user provided context fn or use the default.
/// It also does extra checking and logging to ensure user provided implementations
/// will follow signatures correctly.
fn useCtxFn(comptime fn_name: []const u8) @TypeOf(@field(default, fn_name)) {
    if (!@hasDecl(default, fn_name)) {
        @compileError("Context fn doesn't exist in default implementation");
    }

    const d_fn = @field(default, fn_name);
    if (@hasDecl(context, fn_name)) {
        const c_fn = @field(context, fn_name);
        const c_fn_type = @TypeOf(c_fn);
        const d_fn_type = @TypeOf(d_fn);

        if (c_fn_type != d_fn_type) {
            const d_fn_name = @typeName(d_fn_type);
            @compileError("webview '" ++ fn_name ++ "' does not match expected signature (" ++ d_fn_name ++ ")");
        }

        return c_fn;
    }

    return d_fn;
}

pub const u_root_cache_path_t = extern struct {
    ptr: [*]const u8,
    len: usize,
};

pub export fn u_get_root_cache_path() callconv(.c) u_root_cache_path_t {
    const getCachePath = useCtxFn("getCachePath");

    const path = getCachePath();
    if (std.fs.path.isAbsolute(path)) {
        return .{
            .ptr = path.ptr,
            .len = path.len,
        };
    }

    @panic("Relative paths are not implemented yet");
}

pub export fn u_on_context_init() callconv(.c) void {
    const onContextInit = useCtxFn("onContextInit");

    onContextInit();
}

pub export fn u_on_context_create(u_js_context: *types.u_js_context_t) callconv(.c) void {
    const onContextCreate = useCtxFn("onContextCreate");

    var js_context: types.JSContext = .{ .u_js_context = u_js_context };
    onContextCreate(&js_context);
}
