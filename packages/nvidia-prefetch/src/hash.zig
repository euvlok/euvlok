const std = @import("std");
const version_info = @import("version.zig");

pub const DriverHashes = struct {
    sha256: []const u8,
    sha256_aarch64: []const u8,
    openSha256: []const u8,
    settingsSha256: []const u8,
    persistencedSha256: []const u8,

    pub fn deinit(self: DriverHashes, allocator: std.mem.Allocator) void {
        allocator.free(self.sha256);
        allocator.free(self.sha256_aarch64);
        allocator.free(self.openSha256);
        allocator.free(self.settingsSha256);
        allocator.free(self.persistencedSha256);
    }
};

pub fn fetchAll(
    allocator: std.mem.Allocator,
    io: std.Io,
    client: *std.http.Client,
    driver_version: []const u8,
) !DriverHashes {
    std.debug.print("info: Fetching hashes for NVIDIA driver version {s}...\n", .{driver_version});

    const sha256 = try fetchDriverSha256Sri(allocator, io, client, "x86_64", version_info.x86_64_base_url, driver_version);
    errdefer allocator.free(sha256);

    const sha256_aarch64 = try fetchDriverSha256Sri(allocator, io, client, "aarch64", version_info.aarch64_base_url, driver_version);
    errdefer allocator.free(sha256_aarch64);

    std.debug.print("info: Fetching NVIDIA open kernel modules...\n", .{});
    const openSha256 = try prefetchGithubSourceHash(allocator, io, client, "open-gpu-kernel-modules", driver_version);
    errdefer allocator.free(openSha256);

    std.debug.print("info: Fetching nvidia-settings...\n", .{});
    const settingsSha256 = try prefetchGithubSourceHash(allocator, io, client, "nvidia-settings", driver_version);
    errdefer allocator.free(settingsSha256);

    std.debug.print("info: Fetching nvidia-persistenced...\n", .{});
    const persistencedSha256 = try prefetchGithubSourceHash(allocator, io, client, "nvidia-persistenced", driver_version);

    return .{
        .sha256 = sha256,
        .sha256_aarch64 = sha256_aarch64,
        .openSha256 = openSha256,
        .settingsSha256 = settingsSha256,
        .persistencedSha256 = persistencedSha256,
    };
}

fn fetchDriverSha256Sri(
    allocator: std.mem.Allocator,
    io: std.Io,
    client: *std.http.Client,
    arch: []const u8,
    base_url: []const u8,
    driver_version: []const u8,
) ![]const u8 {
    const driver_name = try std.fmt.allocPrint(allocator, "NVIDIA-Linux-{s}-{s}.run", .{ arch, driver_version });
    defer allocator.free(driver_name);

    const driver_url = try std.fmt.allocPrint(allocator, "{s}/{s}/{s}", .{ base_url, driver_version, driver_name });
    defer allocator.free(driver_url);

    std.debug.print("info: Fetching {s} driver {s}...\n", .{ arch, driver_version });

    var hash_buffer: [64 * 1024]u8 = undefined;
    var hashing = std.Io.Writer.Hashing(std.crypto.hash.sha2.Sha256).init(&hash_buffer);
    const result = try client.fetch(.{ .location = .{ .url = driver_url }, .response_writer = &hashing.writer });
    if (result.status != .ok) return error.HttpRequestFailed;
    try hashing.writer.flush();

    _ = io;
    return sriFromSha256(allocator, hashing.hasher.finalResult());
}

fn prefetchGithubSourceHash(
    allocator: std.mem.Allocator,
    io: std.Io,
    client: *std.http.Client,
    repo: []const u8,
    driver_version: []const u8,
) ![]const u8 {
    const url = try std.fmt.allocPrint(allocator, "{s}/{s}/archive/{s}.tar.gz", .{
        version_info.github_base_url,
        repo,
        driver_version,
    });
    defer allocator.free(url);

    const temp_path = try makeTempPath(allocator, io);
    defer allocator.free(temp_path);
    defer std.Io.Dir.cwd().deleteTree(io, temp_path) catch {};

    try std.Io.Dir.cwd().createDirPath(io, temp_path);
    var temp_dir = try std.Io.Dir.cwd().openDir(io, temp_path, .{ .iterate = true });
    defer temp_dir.close(io);

    var archive = try temp_dir.createFile(io, "source.tar.gz", .{});
    defer archive.close(io);
    var file_buffer: [64 * 1024]u8 = undefined;
    var file_writer = archive.writer(io, &file_buffer);
    const result = try client.fetch(.{ .location = .{ .url = url }, .response_writer = &file_writer.interface });
    if (result.status != .ok) return error.HttpRequestFailed;
    try file_writer.interface.flush();

    try temp_dir.createDir(io, "source", .default_dir);
    var source_dir = try temp_dir.openDir(io, "source", .{ .iterate = true });
    defer source_dir.close(io);

    var archive_reader_file = try temp_dir.openFile(io, "source.tar.gz", .{});
    defer archive_reader_file.close(io);
    var archive_reader_buffer: [64 * 1024]u8 = undefined;
    var archive_reader = archive_reader_file.reader(io, &archive_reader_buffer);
    var decompress_buffer: [std.compress.flate.max_window_len]u8 = undefined;
    var gzip = std.compress.flate.Decompress.init(&archive_reader.interface, .gzip, &decompress_buffer);
    try std.tar.extract(io, source_dir, &gzip.reader, .{ .strip_components = 1 });

    var nar_hash = std.Io.Writer.Hashing(std.crypto.hash.sha2.Sha256).init(&file_buffer);
    try writeNarDirectory(allocator, io, source_dir, &nar_hash.writer);
    try nar_hash.writer.flush();
    return sriFromSha256(allocator, nar_hash.hasher.finalResult());
}

fn makeTempPath(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    var random: [12]u8 = undefined;
    try std.Io.randomSecure(io, &random);

    var encoded: [std.base64.url_safe_no_pad.Encoder.calcSize(random.len)]u8 = undefined;
    _ = std.base64.url_safe_no_pad.Encoder.encode(&encoded, &random);
    return std.fmt.allocPrint(allocator, ".zig-cache/nvidia-prefetch-{s}", .{encoded});
}

fn sriFromSha256(allocator: std.mem.Allocator, digest: [std.crypto.hash.sha2.Sha256.digest_length]u8) ![]const u8 {
    const prefix = "sha256-";
    const encoded_len = std.base64.standard.Encoder.calcSize(digest.len);
    const result = try allocator.alloc(u8, prefix.len + encoded_len);
    @memcpy(result[0..prefix.len], prefix);
    _ = std.base64.standard.Encoder.encode(result[prefix.len..], &digest);
    return result;
}

const NarEntry = struct {
    name: []const u8,
    kind: std.Io.File.Kind,
};

fn writeNarDirectory(allocator: std.mem.Allocator, io: std.Io, dir: std.Io.Dir, writer: *std.Io.Writer) !void {
    try narString(writer, "nix-archive-1");
    try writeNarNode(allocator, io, dir, "", .directory, writer);
}

fn writeNarNode(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    path: []const u8,
    kind: std.Io.File.Kind,
    writer: *std.Io.Writer,
) !void {
    try narString(writer, "(");
    try narString(writer, "type");

    switch (kind) {
        .directory => {
            try narString(writer, "directory");
            var child_dir = if (path.len == 0) dir else try dir.openDir(io, path, .{ .iterate = true });
            defer if (path.len != 0) child_dir.close(io);

            var entries: std.ArrayList(NarEntry) = .empty;
            defer {
                for (entries.items) |entry| allocator.free(entry.name);
                entries.deinit(allocator);
            }

            var it = child_dir.iterate();
            while (try it.next(io)) |entry| {
                try entries.append(allocator, .{
                    .name = try allocator.dupe(u8, entry.name),
                    .kind = entry.kind,
                });
            }
            std.mem.sort(NarEntry, entries.items, {}, entryLessThan);

            for (entries.items) |entry| {
                const child_path = if (path.len == 0)
                    try allocator.dupe(u8, entry.name)
                else
                    try std.fs.path.join(allocator, &.{ path, entry.name });
                defer allocator.free(child_path);

                try narString(writer, "entry");
                try narString(writer, "(");
                try narString(writer, "name");
                try narString(writer, entry.name);
                try narString(writer, "node");
                try writeNarNode(allocator, io, dir, child_path, entry.kind, writer);
                try narString(writer, ")");
            }
        },
        .file => {
            try narString(writer, "regular");
            const stat = try dir.statFile(io, path, .{});
            if (std.Io.File.Permissions.has_executable_bit and
                stat.permissions.toMode() & 0o111 != 0)
            {
                try narString(writer, "executable");
                try narString(writer, "");
            }
            try narString(writer, "contents");

            var file = try dir.openFile(io, path, .{});
            defer file.close(io);
            var buffer: [64 * 1024]u8 = undefined;
            var reader = file.reader(io, &buffer);
            try narBytesFromReader(writer, &reader.interface, stat.size);
        },
        .sym_link => {
            try narString(writer, "symlink");
            try narString(writer, "target");
            var target_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
            const len = try dir.readLink(io, path, &target_buffer);
            try narString(writer, target_buffer[0..len]);
        },
        else => return error.UnsupportedNarFileKind,
    }

    try narString(writer, ")");
}

fn entryLessThan(_: void, a: NarEntry, b: NarEntry) bool {
    return std.mem.lessThan(u8, a.name, b.name);
}

fn narString(writer: *std.Io.Writer, bytes: []const u8) !void {
    try writer.writeInt(u64, bytes.len, .little);
    try writer.writeAll(bytes);
    try narPadding(writer, bytes.len);
}

fn narBytesFromReader(writer: *std.Io.Writer, reader: *std.Io.Reader, len: u64) !void {
    try writer.writeInt(u64, len, .little);
    var remaining = len;
    var buffer: [64 * 1024]u8 = undefined;
    while (remaining > 0) {
        const want: usize = @intCast(@min(remaining, buffer.len));
        try reader.readSliceAll(buffer[0..want]);
        try writer.writeAll(buffer[0..want]);
        remaining -= want;
    }
    try narPadding(writer, @intCast(len % 8));
}

fn narPadding(writer: *std.Io.Writer, len: usize) !void {
    const padding = (8 - (len % 8)) % 8;
    if (padding == 0) return;
    try writer.splatByteAll(0, padding);
}
