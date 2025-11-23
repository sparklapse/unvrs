const std = @import("std");

/// Define a callback
pub fn define(P: type) type {
    const CallbackDefinition = struct {
        pub const Params = P;
        const RootDefinition = @This();

        pub const CCaller = switch (@typeInfo(P)) {
            .void => *const fn (callable: *anyopaque, ctx: *anyopaque) callconv(.c) void,
            else => *const fn (callable: *anyopaque, ctx: *anyopaque, params: P) callconv(.c) void,
        };

        pub fn Callable(T: type) type {
            return *const fn (self: *T, params: P) void;
        }

        pub fn create(Ctx: type) type {
            if (!@hasDecl(Ctx, "callback")) {
                @compileError("A context type must have a public 'callback' decl");
            }

            const callback_info = @typeInfo(@TypeOf(Ctx.callback)).@"fn";
            if (callback_info.params.len != 2) {
                @compileError("Invalid callback parameters");
            }
            if (callback_info.params[0].type.? != *Ctx) {
                @compileError("First callback parameter must be self");
            }
            if (callback_info.return_type.? != void) {
                @compileError("Callbacks can only return void");
            }

            const Callback = struct {
                pub const Definition = RootDefinition;

                context: Ctx,
                callable: Callable(Ctx) = &Ctx.callback,

                pub fn init(initial: Ctx) @This() {
                    return .{
                        .context = initial,
                    };
                }

                pub fn call(self: *@This(), params: P) void {
                    self.callable(&self.context, params);
                }
            };

            return Callback;
        }

        /// This gives a pointer to a C function. You can pass this to C/C++ code if you
        /// want to run a callback from C.
        pub fn getCCaller() CCaller {
            switch (@typeInfo(P)) {
                .void => {
                    return &cCall;
                },
                else => {
                    return &cCallWithParams;
                },
            }
        }

        fn cCall(callable: *anyopaque, ctx: *anyopaque) callconv(.c) void {
            const runner: Callable(anyopaque) = @ptrCast(@alignCast(callable));
            runner(@ptrCast(@alignCast(ctx)), {});
        }

        fn cCallWithParams(callable: *anyopaque, ctx: *anyopaque, params: P) callconv(.c) void {
            const runner: Callable(anyopaque) = @ptrCast(@alignCast(callable));
            runner(@ptrCast(@alignCast(ctx)), params);
        }
    };

    return CallbackDefinition;
}
