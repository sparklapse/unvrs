const std = @import("std");

target: std.Build.ResolvedTarget,
exe: *std.Build.Step.Compile,
id: []const u8 = "com.sparklapse.unvrs",
name: []const u8 = "unvrs",
