const callback = @import("callback");
const Window = @import("./Window.zig");

const WindowResizeParams = extern struct {
    width: f64,
    height: f64,
};
pub const WindowResize = callback.define(WindowResizeParams);
pub extern fn u_window_callback_add_resize(
    c_caller: WindowResize.CCaller,
    win: *Window.u_window_t,
    callable: *anyopaque,
    context: *anyopaque,
) void;
