const builtin = @import("builtin");

const App = @This();

pub const u_app_t = opaque {
    pub extern fn u_app_create() *u_app_t;
    pub extern fn u_app_delete(self: *u_app_t) void;
    pub extern fn u_app_run(self: *u_app_t) void;
};

u_app: *u_app_t,

pub fn init() App {
    const u_app: *u_app_t = .u_app_create();

    return .{
        .u_app = u_app,
    };
}

pub fn free(self: *App) void {
    self.u_app.u_app_delete();
}

pub fn run(self: *App) void {
    self.u_app.u_app_run();
}
