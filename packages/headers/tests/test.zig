const builtin = @import("builtin");

const Test = @This();

pub const CCaller = *const fn (callable: *anyopaque, ctx: *anyopaque) callconv(.c) void;

pub const u_test_t = opaque {
    pub extern fn u_test_create() *u_test_t;
    pub extern fn u_test_delete(self: *u_test_t) void;
    pub extern fn u_test_run(self: *u_test_t) void;
};

u_test: *u_test_t,

pub fn init() Test {
    const u_test: *u_test_t = .u_app_create();

    return .{
        .u_test = u_test,
    };
}

pub fn free(self: *Test) void {
    self.u_test.u_test_delete();
}

pub fn run(self: *Test) void {
    self.u_test.u_test_run();
}

pub const some_opaque_type = opaque {
    pub extern fn call_me_maybe() void;
};

pub const extern_struct = extern struct {
    foo: u32,
    bar: u64,
    ptr: *opaque {},
    str: *u_test_t,
};

pub extern fn reach_into_c(a: u32, b: *anyopaque) void;

pub extern fn take_fn_ptr(a: CCaller) void;

pub extern fn slice_ptr(str: [*:0]const u8) void;
