const std = @import("std");
const core = @import("core");
const View = core.window.View;

const WebView = @This();

pub const u_webview_t = opaque {
    pub extern fn u_webview_create(view: *View.u_view_t, width: i32, height: i32, url: [*:0]const u8) *u_webview_t;
    pub extern fn u_webview_delete(self: *u_webview_t) void;
    pub extern fn u_webview_was_resized(self: *u_webview_t) void;
};

pub const WebViewOptions = struct {
    view: View.ViewOptions = .{},
    start_url: [:0]const u8 = "https://spkl.app",
};

u_webview: *u_webview_t,
view: View,

pub fn init(options: WebViewOptions) WebView {
    const view: View = .init(options.view);
    const u_webview: *u_webview_t = .u_webview_create(
        view.u_view,
        @intFromFloat(options.view.width),
        @intFromFloat(options.view.height),
        options.start_url.ptr,
    );

    return .{
        .u_webview = u_webview,
        .view = view,
    };
}

pub fn free(self: *WebView) void {
    self.u_webview.u_webview_delete();
}
