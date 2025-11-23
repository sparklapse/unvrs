const std = @import("std");
const core = @import("core");
const loop = core.loop;
const win = core.window;
const wv = @import("webview");

const Resizer = win.Window.callbacks.WindowResize.create(struct {
    left: *wv.WebView,
    right: *wv.WebView,

    pub fn callback(self: *@This(), size: win.Window.callbacks.WindowResize.Params) void {
        self.left.view.resize(size.width / 2, size.height);
        self.right.view.resize(size.width / 2, size.height);
        self.right.view.setPos(size.width / 2, 0);
    }
});

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

    var webview_left: wv.WebView = .init(.{
        .view = .{ .width = 400, .height = 500 },
    });
    defer webview_left.free();

    var webview_right: wv.WebView = .init(.{
        .view = .{ .x = 400, .width = 400, .height = 500 },
        .start_url = "https://example.com",
    });
    defer webview_right.free();

    var resize_webviews: Resizer = .init(.{
        .left = &webview_left,
        .right = &webview_right,
    });
    window.addCallback(Resizer, &resize_webviews);

    window.addView(&webview_left.view);
    window.addView(&webview_right.view);

    std.debug.print("Starting...", .{});
    app.run();
    std.debug.print("Done!\n", .{});
}
