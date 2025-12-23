pub const u_js_context_t = opaque {
    pub extern fn u_js_context_set_value_string(
        self: *u_js_context_t,
        k: [*]const u8,
        k_length: usize,
        v: [*]const u8,
        v_length: usize,
    ) void;
};

pub const JSContext = struct {
    u_js_context: *u_js_context_t,

    pub fn setString(self: *JSContext, key: []const u8, value: []const u8) void {
        self.u_js_context.u_js_context_set_value_string(
            key.ptr,
            key.len,
            value.ptr,
            value.len,
        );
    }
};
