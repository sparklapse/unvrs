//! Generate c headers based on zig types

const std = @import("std");
const builtin = @import("builtin");
const module = @import("module");

const template = @embedFile("./template.h");

const StringArray = std.array_list.Aligned([]u8, null);

const CDefinition = struct {
    name: []const u8,
    typedef: []const u8,
    definition: []const u8,
};

const Header = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    types: std.array_list.Aligned(CDefinition, null) = .empty,
    methods: std.array_list.Aligned(CDefinition, null) = .empty,
    header: std.array_list.Aligned(u8, null) = .empty,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Header {
        return .{
            .allocator = allocator,
            .name = name,
        };
    }

    pub fn hasType(self: *Header, name: []const u8) ?CDefinition {
        for (self.types.items) |t| {
            if (std.mem.eql(u8, t.name, name)) return t;
        }

        return null;
    }

    pub fn hasMethod(self: *Header, name: []const u8) ?CDefinition {
        for (self.methods.items) |m| {
            if (std.mem.eql(u8, m.name, name)) return m;
        }

        return null;
    }

    pub fn generate(self: *Header, T: type) []u8 {
        _ = self.mapType(T, null);

        var types = self.allocator.alloc([]const u8, self.types.items.len) catch @panic("OOM");
        var method_typedefs = self.allocator.alloc([]const u8, self.methods.items.len) catch @panic("OOM");
        var methods = self.allocator.alloc([]const u8, self.methods.items.len) catch @panic("OOM");

        {
            var i: usize = 0;
            for (self.types.items) |t| {
                types[i] = t.definition;
                i += 1;
            }
        }

        {
            var i: usize = 0;
            for (self.methods.items) |m| {
                method_typedefs[i] = m.typedef;
                i += 1;
            }
        }

        {
            var i: usize = 0;
            for (self.methods.items) |m| {
                methods[i] = m.definition;
                i += 1;
            }
        }

        const name_upper = std.ascii.allocUpperString(
            self.allocator,
            self.name,
        ) catch @panic("OOM");
        self.header.print(
            self.allocator,
            template,
            .{
                name_upper,
                name_upper,
                std.mem.join(self.allocator, "\n", types) catch @panic("OOM"),
                std.mem.join(self.allocator, "\n", method_typedefs) catch @panic("OOM"),
                std.mem.join(self.allocator, "\n", methods) catch @panic("OOM"),
                name_upper,
            },
        ) catch @panic("OOM");

        return self.header.items;
    }

    // A helper to get the typedef of a function type
    fn mapFnTypedef(self: *Header, comptime T: type, decl_name: ?[]const u8) []const u8 {
        const info = @typeInfo(T).@"fn";
        var c_method_type: std.array_list.Aligned(u8, null) = .empty;
        const c_return = self.mapType(info.return_type.?, null);

        if (c_return) |cr| {
            if (decl_name) |dn| {
                c_method_type.print(
                    self.allocator,
                    "{s} (*{s}_t)(",
                    .{ cr, dn },
                ) catch @panic("OOM");
            } else {
                c_method_type.print(
                    self.allocator,
                    "{s} (*)(",
                    .{cr},
                ) catch @panic("OOM");
            }

            inline for (info.params) |param| {
                const c_param = self.mapType(
                    param.type orelse void,
                    null,
                );
                if (c_param) |cp| {
                    c_method_type.print(
                        self.allocator,
                        "{s},",
                        .{cp},
                    ) catch @panic("OOM");
                } else {
                    c_method_type.print(
                        self.allocator,
                        "/* bad type */ ",
                        .{},
                    ) catch @panic("OOM");
                    std.debug.print("Unable to parse param\n", .{});
                }
            }
            if (info.params.len > 0) _ = c_method_type.pop();
            c_method_type.print(self.allocator, ")", .{}) catch @panic("OOM");

            return c_method_type.items;
        }

        @panic("Not a valid c function");
    }

    /// This will recursively go through a type and update the header with it's information
    fn mapType(
        self: *Header,
        comptime T: type,
        decl_name: ?[]const u8,
    ) ?[]const u8 {
        const info = @typeInfo(T);
        const name = @typeName(T);
        var name_split = std.mem.splitBackwardsScalar(u8, name, '.');
        const name_end = name_split.first();

        switch (info) {
            .@"struct" => |s| {
                if (self.hasType(name)) |existing| return existing.typedef;

                var return_name: ?[]const u8 = null;
                if (s.layout == .@"extern") {
                    var c_struct: std.array_list.Aligned(u8, null) = .empty;
                    c_struct.print(self.allocator,
                        \\typedef struct {s} {{
                        \\
                    , .{name_end}) catch @panic("OOM");
                    inline for (s.fields) |f| {
                        const c_type = self.mapType(f.type, null);
                        if (c_type) |ct| {
                            c_struct.print(
                                self.allocator,
                                "  {s} {s};\n",
                                .{ ct, f.name },
                            ) catch @panic("OOM");
                        } else {
                            c_struct.print(
                                self.allocator,
                                "  // {s} {s};\n",
                                .{ @typeName(f.type), f.name },
                            ) catch @panic("OOM");
                            std.debug.print("Struct field '{s}' ({s}) can't be translated to C\n", .{ f.name, @typeName(f.type) });
                        }
                    }
                    c_struct.print(self.allocator, "}} {s};", .{name_end}) catch @panic("OOM");
                    self.types.append(self.allocator, .{ .name = name, .typedef = name_end, .definition = c_struct.items }) catch @panic("OOM");

                    return_name = name_end;
                }

                inline for (s.decls) |d| {
                    const field = @field(T, d.name);
                    if (@TypeOf(field) != type) {
                        _ = self.mapType(@TypeOf(field), d.name);
                    } else {
                        _ = self.mapType(field, d.name);
                    }
                }

                return return_name;
            },
            .pointer => |p| {
                const c_child = if (@TypeOf(p.child) != type)
                    self.mapType(@TypeOf(p.child), decl_name)
                else
                    self.mapType(p.child, decl_name);

                if (c_child) |cc| {
                    if (@TypeOf(p.child) == type) {
                        switch (@typeInfo(p.child)) {
                            .@"opaque" => {
                                if (!std.mem.eql(u8, cc, "void")) return cc;
                            },
                            .@"fn" => {
                                return cc;
                            },
                            else => {},
                        }
                    }
                    return std.fmt.allocPrint(self.allocator, "{s}*", .{cc}) catch @panic("OOM");
                }
            },
            .@"fn" => |f| {
                if (!f.calling_convention.eql(std.builtin.CallingConvention.c)) return null;
                if (decl_name) |dn| {
                    if (self.hasMethod(dn)) |existing| return existing.typedef;
                    var c_method: std.array_list.Aligned(u8, null) = .empty;
                    const c_return = self.mapType(f.return_type.?, null);

                    if (c_return) |cr| {
                        c_method.print(self.allocator, "{s} {s}(", .{
                            cr,
                            dn,
                        }) catch @panic("OOM");
                        inline for (f.params) |param| {
                            const c_param = self.mapType(
                                param.type orelse void,
                                null,
                            );
                            if (c_param) |cp| {
                                c_method.print(
                                    self.allocator,
                                    "{s},",
                                    .{cp},
                                ) catch @panic("OOM");
                            } else {
                                c_method.print(
                                    self.allocator,
                                    "/* bad type */ ",
                                    .{},
                                ) catch @panic("OOM");
                                std.debug.print("Unable to parse param\n", .{});
                            }
                        }
                        if (f.params.len > 0) _ = c_method.pop();
                        c_method.print(self.allocator, ");", .{}) catch @panic("OOM");
                        const typedef = std.fmt.allocPrint(
                            self.allocator,
                            "typedef {s};",
                            .{self.mapFnTypedef(T, dn)},
                        ) catch @panic("OOM");
                        self.methods.append(
                            self.allocator,
                            .{ .name = dn, .typedef = typedef, .definition = c_method.items },
                        ) catch @panic("OOM");

                        return std.fmt.allocPrint(
                            self.allocator,
                            "{s}_t",
                            .{dn},
                        ) catch @panic("OOM");
                    }
                }

                return self.mapFnTypedef(T, null);
            },
            .@"opaque" => |o| {
                if (self.hasType(name)) |existing| return existing.typedef;
                const dn = decl_name orelse name_end;

                const c_type = std.fmt.allocPrint(
                    self.allocator,
                    "typedef void *{s};",
                    .{dn},
                ) catch @panic("OOM");
                self.types.append(self.allocator, .{ .name = name, .typedef = dn, .definition = c_type }) catch @panic("OOM");

                inline for (o.decls) |d| {
                    const field = @field(T, d.name);
                    if (@TypeOf(field) != type) {
                        _ = self.mapType(@TypeOf(field), d.name);
                    } else {
                        _ = self.mapType(field, d.name);
                    }
                }

                return dn;
            },
            .int => |i| {
                if (std.mem.eql(u8, @typeName(T), "usize")) return "size_t";
                if (i.signedness == .signed) {
                    return std.fmt.comptimePrint("int{}_t", .{i.bits});
                } else {
                    return std.fmt.comptimePrint("uint{}_t", .{i.bits});
                }
            },
            .float => |f| {
                if (f.bits == 32) return "float";
                if (f.bits == 64) return "double";
            },
            .bool => {
                return "bool";
            },
            .void => {
                return "void";
            },
            .@"union" => {
                // No C type conversion available
            },
            else => {
                std.debug.print("Unable to handle type '{s}' ({s})\n", .{ @typeName(T), @tagName(info) });
            },
        }

        return null;
    }
};

pub fn main() void {
    var da: std.heap.DebugAllocator(.{}) = .init;
    var aa: std.heap.ArenaAllocator = .init(da.allocator());
    defer aa.deinit();

    const allocator = aa.allocator();

    var args = std.process.argsWithAllocator(allocator) catch @panic("OOM");
    _ = args.skip();

    const name = args.next();
    if (name == null) @panic("No name provided");

    var header: Header = .init(allocator, name.?);
    const output = header.generate(module);

    var stdout_buf: [100_000]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&stdout_buf);
    _ = stdout.interface.write(output) catch @panic("OOM");
    stdout.interface.flush() catch @panic("IO Error");
}
