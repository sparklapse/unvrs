const std = @import("std");
const builtin = @import("builtin");
const core = @import("core");
const View = core.window.View;
const Window = core.window.Window;

const WebView = @This();

pub const u_webview_t = opaque {
    pub extern fn u_webview_create(view: *View.u_view_t) *u_webview_t;
    pub extern fn u_webview_delete(self: *u_webview_t) void;
    pub extern fn u_webview_load_url(self: *u_webview_t, url: [*]const u8, url_length: usize) void;
    pub extern fn u_webview_run_js(self: *u_webview_t, js: [*]const u8, js_length: usize) void;
};

pub const WebViewOptions = struct {
    view: View.ViewOptions = .{},
    start_url: []const u8 = "https://spkl.app",
};

u_webview: *u_webview_t,
view: View,

pub fn init(options: WebViewOptions) WebView {
    const view: View = .init(options.view);
    const u_webview: *u_webview_t = .u_webview_create(view.u_view);

    u_webview.u_webview_load_url( options.start_url.ptr, options.start_url.len);

    return .{
        .u_webview = u_webview,
        .view = view,
    };
}

pub fn free(self: *WebView) void {
    self.u_webview.u_webview_delete();
}

pub fn runJs(self: *WebView, js: []const u8) void {
    self.u_webview.u_webview_run_js(js.ptr, js.len);
}
