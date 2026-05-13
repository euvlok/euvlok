const std = @import("std");
const hash = @import("hash.zig");
const nix_file = @import("nix_file.zig");
const version_info = @import("version.zig");

const Options = struct {
    update: bool = true,
    requested_version: ?[]const u8 = null,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var client: std.http.Client = .{ .allocator = allocator, .io = io };
    defer client.deinit();

    const options = try parseArgs(init.minimal.args, allocator);
    const driver_version = try resolveVersion(allocator, &client, options.requested_version);
    defer if (options.requested_version == null) allocator.free(driver_version);

    try exitIfCurrent(allocator, io, options.update, driver_version, options.requested_version);

    const hashes = try hash.fetchAll(allocator, io, &client, driver_version);
    defer hashes.deinit(allocator);

    logHashes(hashes);
    if (options.update) try nix_file.update(allocator, io, driver_version, hashes);
}

fn parseArgs(args: std.process.Args, allocator: std.mem.Allocator) !Options {
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
            usage();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "-")) {
            std.debug.print("unknown option: {s}\n", .{arg});
            usage();
            std.process.exit(2);
        } else if (options.requested_version == null) {
            options.requested_version = arg;
        } else {
            std.debug.print("unexpected argument: {s}\n", .{arg});
            usage();
            std.process.exit(2);
        }
    }
    return options;
}

fn usage() void {
    std.debug.print(
        \\usage: nvidia-prefetch [--update|--no-update] [version]
        \\
        \\Fetch NVIDIA driver hashes and optionally update nvidia-driver.nix.
        \\
    , .{});
}

fn resolveVersion(
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    requested_version: ?[]const u8,
) ![]const u8 {
    if (requested_version) |driver_version| return driver_version;

    const driver_version = try version_info.fetchLatest(allocator, client);
    std.debug.print("success: Using latest driver version: {s}\n", .{driver_version});
    return driver_version;
}

fn exitIfCurrent(
    allocator: std.mem.Allocator,
    io: std.Io,
    update: bool,
    driver_version: []const u8,
    requested_version: ?[]const u8,
) !void {
    if (!update) return;

    const current = try nix_file.currentVersion(allocator, io) orelse return;
    defer allocator.free(current);

    if (requested_version == null and try version_info.compare(driver_version, current) < 0) {
        std.debug.print(
            "Refusing to downgrade NVIDIA driver from {s} to {s}. Specify a version manually if this downgrade is intentional.\n",
            .{ current, driver_version },
        );
        std.process.exit(1);
    }

    if (!std.mem.eql(u8, current, driver_version)) return;

    std.debug.print("info: Current version ({s}) is already up to date\n", .{current});
    std.debug.print("info: Use --no-update to force hash recalculation\n", .{});
    std.process.exit(0);
}

fn logHashes(hashes: hash.DriverHashes) void {
    std.debug.print(
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
