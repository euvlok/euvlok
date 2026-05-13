const std = @import("std");
const DriverHashes = @import("hash.zig").DriverHashes;

pub fn currentVersion(allocator: std.mem.Allocator, io: std.Io) !?[]const u8 {
    const path = try find(allocator, io) orelse return null;
    defer allocator.free(path);

    const content = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(content);

    return extractStringValue(allocator, content, "version");
}

pub fn update(allocator: std.mem.Allocator, io: std.Io, driver_version: []const u8, hashes: DriverHashes) !void {
    const path = try find(allocator, io) orelse return error.NvidiaDriverNixNotFound;
    defer allocator.free(path);

    std.debug.print("info: Updating {s}...\n", .{path});

    const content = try format(allocator, driver_version, hashes);
    defer allocator.free(content);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = content });
    std.debug.print("success: Successfully updated {s}\n", .{path});
}

fn find(allocator: std.mem.Allocator, io: std.Io) !?[]const u8 {
    const cwd = try std.process.currentPathAlloc(io, allocator);
    defer allocator.free(cwd);

    var cursor: []const u8 = cwd;
    while (true) {
        const candidate = try std.fs.path.join(allocator, &.{ cursor, "modules/nixos/nvidia-driver.nix" });
        std.Io.Dir.cwd().access(io, candidate, .{}) catch |err| {
            allocator.free(candidate);
            switch (err) {
                error.FileNotFound => {},
                else => |e| return e,
            }
            const parent = std.fs.path.dirname(cursor) orelse return null;
            if (std.mem.eql(u8, parent, cursor)) return null;
            cursor = parent;
            continue;
        };
        return candidate;
    }
}

fn extractStringValue(allocator: std.mem.Allocator, content: []const u8, name: []const u8) !?[]const u8 {
    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (!std.mem.startsWith(u8, trimmed, name)) continue;

        var rest = std.mem.trim(u8, trimmed[name.len..], " \t");
        if (rest.len == 0 or rest[0] != '=') continue;

        rest = std.mem.trim(u8, rest[1..], " \t");
        if (rest.len == 0 or rest[0] != '"') continue;

        const end = std.mem.indexOfScalarPos(u8, rest, 1, '"') orelse continue;
        return try allocator.dupe(u8, rest[1..end]);
    }

    return null;
}

fn format(allocator: std.mem.Allocator, driver_version: []const u8, hashes: DriverHashes) ![]const u8 {
    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();

    try out.writer.writeAll("{\n");
    try writeString(&out.writer, "version", driver_version);
    try writeString(&out.writer, "sha256_64bit", hashes.sha256);
    try writeString(&out.writer, "sha256_aarch64", hashes.sha256_aarch64);
    try writeString(&out.writer, "openSha256", hashes.openSha256);
    try writeString(&out.writer, "settingsSha256", hashes.settingsSha256);
    try writeString(&out.writer, "persistencedSha256", hashes.persistencedSha256);
    try out.writer.writeAll("}\n");
    return out.toOwnedSlice();
}

fn writeString(writer: *std.Io.Writer, name: []const u8, value: []const u8) !void {
    try writer.print("  {s} = \"", .{name});
    for (value) |byte| switch (byte) {
        '\\', '"' => try writer.print("\\{c}", .{byte}),
        '\n' => try writer.writeAll("\\n"),
        '\r' => try writer.writeAll("\\r"),
        '\t' => try writer.writeAll("\\t"),
        else => try writer.writeByte(byte),
    };
    try writer.writeAll("\";\n");
}
