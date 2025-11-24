const std = @import("std");
const builtin = @import("builtin");

const View = @import("./View.zig");

const Window = @This();

pub const u_window_t = opaque {
    pub extern fn u_window_create(x: f64, y: f64, width: f64, height: f64) *u_window_t;
    pub extern fn u_window_delete(self: *u_window_t) void;
    pub extern fn u_window_is_visible(self: *u_window_t) bool;
    pub extern fn u_window_set_visible(self: *u_window_t, visible: bool) void;
    pub extern fn u_window_set_background_color(self: *u_window_t, r: u8, g: u8, b: u8, a: u8) void;
    pub extern fn u_window_get_root_view(self: *u_window_t) *View.u_view_t;
    pub extern fn u_window_add_view(self: *u_window_t, view: *View.u_view_t) void;
};

pub const WindowOptions = struct {
    x: f64 = 0,
    y: f64 = 0,
    width: f64 = 700,
    height: f64 = 400,
};

u_window: *u_window_t,

pub fn init(options: WindowOptions) Window {
    const u_window: *u_window_t = .u_window_create(
        options.x,
        options.y,
        options.width,
        options.height,
    );

    return .{
        .u_window = u_window,
    };
}

pub fn free(self: *Window) void {
    self.u_window.u_window_delete();
}

pub fn isVisible(self: *Window) bool {
    return self.u_window.u_window_is_visible();
}

pub fn show(self: *Window) void {
    self.u_window.u_window_set_visible(true);
}

pub fn hide(self: *Window) void {
    self.u_window.u_window_set_visible(false);
}

// NOTE: If color space becomes an issue and more control is needed, it should
// become it's own module and imported.
const Color = struct {
    r: u8 = 255,
    g: u8 = 255,
    b: u8 = 255,
    a: u8 = 255,
};
pub fn setBackgroundColor(self: *Window, color: Color) void {
    self.u_window.u_window_set_background_color(
        color.r,
        color.g,
        color.b,
        color.a,
    );
}

pub fn addView(self: *Window, view: *View) void {
    self.u_window.u_window_add_view(view.u_view);
}

pub const callbacks = @import("./WindowCallbacks.zig");

pub fn addCallback(self: *Window, comptime T: type, instance: *T) void {
    if (!@hasField(T, "callable") or !@hasField(T, "context")) {
        @compileError("A valid callback type was not provided");
    }

    const add = switch (@TypeOf(instance.callable)) {
        callbacks.WindowResize.Callable(@TypeOf(instance.context)) => callbacks.u_window_callback_add_resize,
        else => @compileError("Callback type not supported"),
    };
    add(T.Definition.getCCaller(), self.u_window, @constCast(instance.callable), @constCast(&instance.context));
}
