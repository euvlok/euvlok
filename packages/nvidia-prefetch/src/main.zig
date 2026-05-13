const std = @import("std");
const hash = @import("hash.zig");
const nix_file = @import("nix_file.zig");
const version_info = @import("version.zig");

const stdio_buffer_size = 4096;
const success_exit_code = 0;
const usage_error_exit_code = 2;
const downgrade_refused_exit_code = 1;

const Options = struct {
    update: bool = true,
    requested_version: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var stdout_buffer: [stdio_buffer_size]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &stdout_buffer);
    defer stdout.interface.flush() catch {};

    var stderr_buffer: [stdio_buffer_size]u8 = undefined;
    var stderr = std.Io.File.stderr().writer(io, &stderr_buffer);
    defer stderr.interface.flush() catch {};

    var client: std.http.Client = .{ .allocator = allocator, .io = io };
    defer client.deinit();

    const options = try parseArgs(init.minimal.args, allocator, &stderr.interface);
    const driver_version = try resolveVersion(allocator, &client, options.requested_version, &stderr.interface);
    defer if (options.requested_version == null) allocator.free(driver_version);

    try exitIfCurrent(allocator, io, &stderr.interface, options.update, driver_version, options.requested_version);

    const hashes = try hash.fetchAll(allocator, io, &client, driver_version, &stderr.interface);
    defer hashes.deinit(allocator);

    try logHashes(&stdout.interface, hashes);
    if (options.update) try nix_file.update(allocator, io, &stderr.interface, driver_version, hashes);
}

fn parseArgs(args: std.process.Args, allocator: std.mem.Allocator, stderr: *std.Io.Writer) !Options {
    var iterator = try std.process.Args.Iterator.initAllocator(args, allocator);
    defer iterator.deinit();

    _ = iterator.skip();
    var options: Options = .{};
    while (iterator.next()) |arg| {
        if (std.mem.eql(u8, arg, "--no-update")) {
            options.update = false;
        } else if (std.mem.eql(u8, arg, "--update")) {
            options.update = true;
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try usage(stderr);
            try stderr.flush();
            std.process.exit(success_exit_code);
        } else if (std.mem.startsWith(u8, arg, "-")) {
            try stderr.print("unknown option: {s}\n", .{arg});
            try usage(stderr);
            try stderr.flush();
            std.process.exit(usage_error_exit_code);
        } else if (options.requested_version == null) {
            options.requested_version = arg;
        } else {
            try stderr.print("unexpected argument: {s}\n", .{arg});
            try usage(stderr);
            try stderr.flush();
            std.process.exit(usage_error_exit_code);
        }
    }
    return options;
}

fn usage(stderr: *std.Io.Writer) !void {
    try stderr.writeAll(
        \\usage: nvidia-prefetch [--update|--no-update] [version]
        \\
        \\Fetch NVIDIA driver hashes and optionally update nvidia-driver.nix.
        \\
    );
}

fn resolveVersion(
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    requested_version: ?[]const u8,
    stderr: *std.Io.Writer,
) ![]const u8 {
    if (requested_version) |driver_version| return driver_version;

    const driver_version = try version_info.fetchLatest(allocator, client, stderr);
    try stderr.print("success: Using latest driver version: {s}\n", .{driver_version});
    return driver_version;
}

fn exitIfCurrent(
    allocator: std.mem.Allocator,
    io: std.Io,
    stderr: *std.Io.Writer,
    update: bool,
    driver_version: []const u8,
    requested_version: ?[]const u8,
) !void {
    if (!update) return;

    const current = try nix_file.currentVersion(allocator, io) orelse return;
    defer allocator.free(current);

    if (requested_version == null and try version_info.compare(driver_version, current) < 0) {
        try stderr.print(
            "Refusing to downgrade NVIDIA driver from {s} to {s}. Specify a version manually if this downgrade is intentional.\n",
            .{ current, driver_version },
        );
        try stderr.flush();
        std.process.exit(downgrade_refused_exit_code);
    }

    if (!std.mem.eql(u8, current, driver_version)) return;

    try stderr.print("info: Current version ({s}) is already up to date\n", .{current});
    try stderr.writeAll("info: Use --no-update to force hash recalculation\n");
    try stderr.flush();
    std.process.exit(success_exit_code);
}

fn logHashes(stdout: *std.Io.Writer, hashes: hash.DriverHashes) !void {
    try stdout.print(
        \\
        \\success: Hash computation completed!
        \\
        \\sha256 = "{s}";
        \\sha256_aarch64 = "{s}";
        \\openSha256 = "{s}";
        \\settingsSha256 = "{s}";
        \\persistencedSha256 = "{s}";
        \\
    , .{ hashes.sha256, hashes.sha256_aarch64, hashes.openSha256, hashes.settingsSha256, hashes.persistencedSha256 });
}
