const std = @import("std");
const builtin = @import("builtin");
const core = @import("core");
const View = core.window.View;
const Window = core.window.Window;

const WebView = @This();

pub const u_webview_t = opaque {
    pub extern fn u_webview_create(view: *View.u_view_t, width: i32, height: i32, url: [*:0]const u8) *u_webview_t;
    pub extern fn u_webview_delete(self: *u_webview_t) void;
    pub extern fn u_webview_open_dev_tools(self: *u_webview_t) void;
    pub extern fn u_webview_close_dev_tools(self: *u_webview_t) void;
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

/// The first time calling this will create the window to place dev tools into
/// using the options provided. Subsequent calls will focus the existing window.
pub fn openDevTools(self: *WebView) void {
    // TODO: Should check platform and backend since mobile devices won't usually
    // have dev tools support

    self.u_webview.u_webview_open_dev_tools();
}

/// This will close dev tools and free the window it was attached to
pub fn closeDevTools(self: *WebView) void {
    self.u_webview.u_webview_close_dev_tools();
}
