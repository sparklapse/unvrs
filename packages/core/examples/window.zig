const std = @import("std");
const core = @import("core");
const loop = core.loop;
const win = core.window;

// const WindowResize = win.Window.callbacks.WindowResize;
// const Resizer = WindowResize.create(struct {
//     pub fn callback(self: *@This(), params: WindowResize.Params) void {
//         _ = self;
//         std.debug.print("w: {} - h: {}\n", .{params.width, params.height});
//     }
// });

pub fn main() !void {
    var app: loop.App = .init();
    defer app.free();

    var window: win.Window = .init(.{
        .x = 800,
        .y = 300,
        .width = 800,
        .height = 500,
    });
    defer window.free();

    // const resize_cb: Resizer = .init(.{});
    // window.addCallback(resize_cb);

    std.debug.print("Starting...", .{});
    app.run();
    std.debug.print("Done!\n", .{});
}
