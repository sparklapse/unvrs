const callback = @import("callback");
const WebView = @import("./WebView.zig");

const WebViewMessageParams = extern struct {
};
pub const WebViewMessage = callback.define(WebViewMessageParams);
pub extern fn u_webview_callback_message(
    c_caller: WebViewMessage.CCaller,
    wv: *WebView.u_webview_t,
    callable: *anyopaque,
    context: *anyopaque,
) void;
