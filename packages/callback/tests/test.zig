const std = @import("std");
const callback = @import("callback");

test "echo callback" {
    const EchoDef = callback.define(struct { c: u32 });
    const Echo = EchoDef.create(struct {
        pub fn callback(self: *@This(), params: EchoDef.Params) void {
            _ = self;
            std.debug.print("Echo ({})\n", .{params.c});
        }
    });

    var on_echo: Echo = .init(.{});
    on_echo.call(.{ .c = 0 });
    on_echo.call(.{ .c = 1 });
    on_echo.call(.{ .c = 2 });
}

test "echo callback from c" {
    const EchoDef = callback.define(void);
    const Echo = EchoDef.create(struct {
        pub fn callback(self: *@This(), params: EchoDef.Params) void {
            _ = self;
            _ = params;
            std.debug.print("Echo from C\n", .{});
        }
    });

    const giveContextToC = @extern(
        *const fn (caller: EchoDef.CCaller, callable: *anyopaque, context: *anyopaque) callconv(.c) void,
        .{ .name = "giveContextToC" },
    );
    const callbackFromC = @extern(
        *const fn () callconv(.c) void,
        .{ .name = "callbackFromC" },
    );

    var on_echo: Echo = .init(.{});

    giveContextToC(EchoDef.getCCaller(), &on_echo, @constCast(on_echo.callable));
    callbackFromC();
}
