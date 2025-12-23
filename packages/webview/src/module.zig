pub const WebView = @import("./WebView.zig");

pub const context = @import("./context/module.zig");

comptime {
    // We need to pull the context bindings out here so that zig will
    // recognise exported c functions and include them in the library
    _ = &context.bindings;
}
