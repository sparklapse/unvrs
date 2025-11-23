const std = @import("std");

const View = @This();

pub const u_view_t = opaque {
    pub extern fn u_view_create(x: f64, y: f64, width: f64, height: f64) *u_view_t;
    pub extern fn u_view_resize(self: *u_view_t, width: f64, height: f64) void;
    pub extern fn u_view_set_pos(self: *u_view_t, x: f64, y: f64) void;
};

pub const ViewOptions = struct {
    x: f64 = 0,
    y: f64 = 0,
    width: f64 = 700,
    height: f64 = 400,
};

u_view: *u_view_t,

pub fn init(options: ViewOptions) View {
    const u_view: *u_view_t = .u_view_create(
        options.x,
        options.y,
        options.width,
        options.height,
    );

    return .{
        .u_view = u_view,
    };
}

// pub fn free(self: *View) void {
// }

pub fn setPos(self: *View, x: f64, y: f64) void {
    self.u_view.u_view_set_pos(x, y);
}

pub fn resize(self: *View, width: f64, height: f64) void {
    self.u_view.u_view_resize(width, height);
}
