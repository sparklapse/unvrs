const std = @import("std");
const builtin = @import("builtin");
const package = @import("./build.zig.zon");

pub fn build(b: *std.Build) void {
    // Tests
    const test_step = b.step("test", "Generate a test header");
    const test_out = generate(b, .{
        .name = "test",
        .root_source_file = b.path("tests/test.zig"),
    });
    const test_copy = b.addInstallFileWithDir(
        test_out.path(b, "test.h"),
        .prefix,
        "test/test.h",
    );

    test_step.dependOn(&test_copy.step);
}

pub const HeaderOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    imports: []const std.Build.Module.Import = &.{},
};

pub fn importsFromTable(owner: *std.Build, table: std.StringArrayHashMapUnmanaged(*std.Build.Module)) []std.Build.Module.Import {
    const imports = owner.allocator.alloc(std.Build.Module.Import, table.count()) catch @panic("OOM");

    var iter = table.iterator();
    while (iter.next()) |item| {
        imports[iter.index - 1] = .{ .name = item.key_ptr.*, .module = item.value_ptr.* };
    }

    return imports;
}

pub fn generate(owner: *std.Build, options: HeaderOptions) std.Build.LazyPath {
    const generator_root = owner.path("src/exe.zig");

    const generator_mod = owner.createModule(.{
        .target = owner.graph.host,
        .root_source_file = generator_root,
        .imports = &.{
            .{
                .name = "module",
                .module = owner.createModule(.{
                    .root_source_file = options.root_source_file,
                    .imports = options.imports,
                }),
            },
        },
    });

    const generator_exe = owner.addExecutable(.{
        .name = owner.fmt("{s}_headers_gen", .{options.name}),
        .root_module = generator_mod,
    });

    const generator_run = owner.addRunArtifact(generator_exe);
    generator_run.addArg(options.name);
    const generator_out = generator_run.captureStdOut();

    const wf = owner.addWriteFiles();
    _ = wf.addCopyFile(generator_out, owner.fmt("{s}.h", .{options.name}));

    return wf.getDirectory();
}
