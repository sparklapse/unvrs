const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    _ = b; // stub
}

fn getCompilerForLang(lang: std.Build.Module.CSourceLanguage) []const u8 {
    return switch (lang) {
        .c => "zig cc -xc",
        .cpp => "zig c++ -xc++",
        .objective_c => "zig cc -xobjective-c",
        .objective_cpp => "zig cc -xobjective-c++",
        else => "unknown",
    };
}

const Generator = struct {
    step: std.Build.Step,
    module: *std.Build.Module,
    include_flags: std.array_list.Aligned(u8, null),
    json: std.json.Array,

    fn dependPaths(step: *std.Build.Step, module: *std.Build.Module) void {
        for (module.include_dirs.items) |dir| {
            dir.path.addStepDependencies(step);
        }

        for (module.import_table.values()) |import| {
            dependPaths(step, import);
        }
    }

    pub fn create(b: *std.Build, module: *std.Build.Module) *Generator {
        const self = b.allocator.create(Generator) catch @panic("OOM");
        self.* = Generator{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "compile_commands",
                .owner = b,
                .makeFn = make,
            }),
            .module = module,
            .include_flags = std.array_list.Aligned(u8, null).initCapacity(
                b.allocator,
                20,
            ) catch @panic("OOM"),
            .json = std.json.Array.initCapacity(
                b.allocator,
                100,
            ) catch @panic("OOM"),
        };
        dependPaths(&self.step, module);
        return self;
    }

    fn loadModuleIncludes(self: *Generator, module: *std.Build.Module) !void {
        const b = self.step.owner;
        for (module.include_dirs.items) |include| {
            switch (include) {
                .path => |path| {
                    const path_str = try path.getPath3(b, &self.step).toString(b.allocator);
                    try self.include_flags.print(b.allocator, "-I{s} ", .{path_str});
                },
                else => {},
            }
        }

        for (module.import_table.values()) |import| {
            if (import.owner != self.module.owner) continue;
            try self.loadModuleIncludes(import);
        }
    }

    fn loadModuleObjects(self: *Generator, module: *std.Build.Module) !void {
        const b = self.step.owner;
        for (module.link_objects.items) |obj| {
            const directory = try b.path("").getPath3(b, &self.step).toString(b.allocator);
            switch (obj) {
                .c_source_file => |source| {
                    var command: std.json.ObjectMap = .init(b.allocator);
                    try command.put("directory", .{ .string = directory });
                    try command.put("file", .{
                        .string = try source.file.getPath3(b, &self.step).toString(b.allocator),
                    });
                    const compiler = getCompilerForLang(source.language orelse std.Build.Module.CSourceLanguage.c);
                    try command.put("command", .{
                        .string = try std.mem.join(b.allocator, " ", &[_][]const u8{
                            compiler,
                            try std.mem.join(b.allocator, " ", source.flags),
                            self.include_flags.items,
                        }),
                    });
                    try self.json.append(.{ .object = command });
                },
                .c_source_files => |sources| {
                    const compiler = getCompilerForLang(sources.language orelse std.Build.Module.CSourceLanguage.c);
                    for (sources.files) |path| {
                        var command: std.json.ObjectMap = .init(b.allocator);
                        try command.put("directory", .{ .string = directory });
                        try command.put("file", .{ .string = path });
                        try command.put("command", .{
                            .string = try std.mem.join(b.allocator, " ", &[_][]const u8{
                                compiler,
                                try std.mem.join(b.allocator, " ", sources.flags),
                                self.include_flags.items,
                            }),
                        });
                        try self.json.append(.{ .object = command });
                    }
                },
                else => {},
            }
        }

        for (module.import_table.values()) |import| {
            if (import.owner != self.module.owner) continue;
            try self.loadModuleObjects(import);
        }
    }

    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) !void {
        _ = options;
        const b = step.owner;
        var generator: *Generator = @fieldParentPtr("step", step);

        if (builtin.os.tag == .macos) {
            try generator.include_flags.print(
                b.allocator,
                "-isysroot {s} ",
                .{"/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"},
            );
        }
        try generator.loadModuleIncludes(generator.module);
        try generator.loadModuleObjects(generator.module);

        var json_writer: std.io.Writer.Allocating = .init(b.allocator);
        try std.json.fmt(generator.json.items, .{ .whitespace = .indent_2 }).format(&json_writer.writer);

        const json_string = json_writer.toArrayList();
        const json_path = try b.path("compile_commands.json").getPath3(b, step).toString(b.allocator);
        var json_file = try std.fs.createFileAbsolute(json_path, .{});
        defer json_file.close();
        _ = try json_file.write(json_string.items);
    }
};

pub fn generate(owner: *std.Build, module: *std.Build.Module) *Generator {
    return Generator.create(owner, module);
}
