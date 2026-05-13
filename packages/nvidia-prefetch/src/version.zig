const std = @import("std");

pub const x86_64_base_url = "https://download.nvidia.com/XFree86/Linux-x86_64";
pub const aarch64_base_url = "https://download.nvidia.com/XFree86/Linux-aarch64";
pub const github_base_url = "https://github.com/NVIDIA";

pub fn fetchLatest(allocator: std.mem.Allocator, client: *std.http.Client) ![]const u8 {
    std.debug.print("info: Fetching latest NVIDIA driver version from all platforms...\n", .{});

    var x86 = try fetchFromPlatform(allocator, client, x86_64_base_url, "x86_64");
    defer deinitVersionList(allocator, &x86);

    var aarch = try fetchFromPlatform(allocator, client, aarch64_base_url, "aarch64");
    defer deinitVersionList(allocator, &aarch);

    const latest = try findLatestShared(x86.items, aarch.items) orelse return error.NoSharedNvidiaVersion;
    return allocator.dupe(u8, latest);
}

fn fetchFromPlatform(
    allocator: std.mem.Allocator,
    client: *std.http.Client,
    base_url: []const u8,
    name: []const u8,
) !std.ArrayList([]const u8) {
    std.debug.print("info: Checking {s} platform...\n", .{name});

    const url = try std.fmt.allocPrint(allocator, "{s}/", .{base_url});
    defer allocator.free(url);

    var body: std.Io.Writer.Allocating = .init(allocator);
    defer body.deinit();
    const result = try client.fetch(.{ .location = .{ .url = url }, .response_writer = &body.writer });
    if (result.status != .ok) return error.HttpRequestFailed;

    var versions = try parseVersionsFromIndex(allocator, body.written());
    errdefer deinitVersionList(allocator, &versions);

    if (versions.items.len == 0) return error.NoNvidiaVersionsFound;
    std.mem.sort([]const u8, versions.items, {}, lessThan);
    return versions;
}

pub fn parseVersionsFromIndex(allocator: std.mem.Allocator, html: []const u8) !std.ArrayList([]const u8) {
    var versions = try std.ArrayList([]const u8).initCapacity(allocator, 16);
    errdefer deinitVersionList(allocator, &versions);

    var index: usize = 0;
    while (std.mem.indexOfPos(u8, html, index, "href=")) |href_start| {
        const quote_index = href_start + "href=".len;
        if (quote_index >= html.len) break;

        const quote = html[quote_index];
        if (quote != '\'' and quote != '"') {
            index = quote_index + 1;
            continue;
        }

        const value_start = quote_index + 1;
        const value_end = std.mem.indexOfScalarPos(u8, html, value_start, quote) orelse break;
        const href = html[value_start..value_end];
        const trimmed = std.mem.trim(u8, href, "/");
        if (isValid(trimmed)) {
            try versions.append(allocator, try allocator.dupe(u8, trimmed));
        }
        index = value_end + 1;
    }

    std.mem.sort([]const u8, versions.items, {}, lessThan);
    return versions;
}

fn deinitVersionList(allocator: std.mem.Allocator, versions: *std.ArrayList([]const u8)) void {
    for (versions.items) |item| allocator.free(item);
    versions.deinit(allocator);
}

fn isValid(version: []const u8) bool {
    var saw_dot = false;
    var previous_dot = false;

    if (version.len == 0) return false;
    for (version) |byte| switch (byte) {
        '0'...'9' => previous_dot = false,
        '.' => {
            if (previous_dot) return false;
            saw_dot = true;
            previous_dot = true;
        },
        else => return false,
    };

    return saw_dot and version[0] != '.' and version[version.len - 1] != '.';
}

fn parsePart(part: []const u8) !u64 {
    if (part.len == 0) return error.InvalidNvidiaVersion;
    return std.fmt.parseInt(u64, part, 10) catch error.InvalidNvidiaVersion;
}

pub fn compare(a: []const u8, b: []const u8) !i8 {
    if (!isValid(a) or !isValid(b)) return error.InvalidNvidiaVersion;

    var a_parts = std.mem.splitScalar(u8, a, '.');
    var b_parts = std.mem.splitScalar(u8, b, '.');
    while (true) {
        const a_part = a_parts.next();
        const b_part = b_parts.next();
        if (a_part == null and b_part == null) return 0;

        const a_value = if (a_part) |part| try parsePart(part) else 0;
        const b_value = if (b_part) |part| try parsePart(part) else 0;
        if (a_value < b_value) return -1;
        if (a_value > b_value) return 1;
    }
}

pub fn lessThan(_: void, a: []const u8, b: []const u8) bool {
    return (compare(a, b) catch 0) < 0;
}

pub fn findLatestShared(versions1: []const []const u8, versions2: []const []const u8) !?[]const u8 {
    var latest: ?[]const u8 = null;
    for (versions1) |left| {
        for (versions2) |right| {
            if (!std.mem.eql(u8, left, right)) continue;
            if (latest == null or try compare(left, latest.?) > 0) latest = left;
            break;
        }
    }
    return latest;
}

test "accepts and sorts NVIDIA versions with leading-zero components" {
    var versions = [_][]const u8{ "580.126.18", "595.71.05", "575.64.05" };
    std.mem.sort([]const u8, &versions, {}, lessThan);
    try std.testing.expectEqualStrings("575.64.05", versions[0]);
    try std.testing.expectEqualStrings("580.126.18", versions[1]);
    try std.testing.expectEqualStrings("595.71.05", versions[2]);
}

test "selects the newest common version without semver rules" {
    const left = [_][]const u8{ "580.126.18", "595.71.05" };
    const right = [_][]const u8{ "575.64.05", "580.126.18", "595.71.05" };
    const latest = (try findLatestShared(&left, &right)).?;
    try std.testing.expectEqualStrings("595.71.05", latest);
}

test "parses NVIDIA directory index hrefs as served" {
    const html =
        \\<!-- Auto-generated directory index; do not edit -->
        \\<ul class='directorycontents'>
        \\  <li><span class='dir'><a href='..'>..</a></span></li>
        \\  <li><span class='dir'><a href='1.0-4499/'>1.0-4499/</a></span></li>
        \\  <li><span class='dir'><a href='525.60.13/'>525.60.13/</a></span></li>
        \\  <li><span class='dir'><a href='595.71.05/'>595.71.05/</a></span></li>
        \\</ul>
    ;

    var versions = try parseVersionsFromIndex(std.testing.allocator, html);
    defer deinitVersionList(std.testing.allocator, &versions);

    try std.testing.expectEqual(@as(usize, 2), versions.items.len);
    try std.testing.expectEqualStrings("525.60.13", versions.items[0]);
    try std.testing.expectEqualStrings("595.71.05", versions.items[1]);
}

test "parses mixed quote styles and versions without trailing slash" {
    const html =
        \\<a href="580.126.18/">580.126.18/</a>
        \\<a href='575.64.05'>575.64.05</a>
        \\<a href=not-quoted>not-quoted</a>
        \\<a href='latest.txt'>latest.txt</a>
        \\<a href='/absolute/580.95.05/'>absolute path should not parse</a>
    ;

    var versions = try parseVersionsFromIndex(std.testing.allocator, html);
    defer deinitVersionList(std.testing.allocator, &versions);

    try std.testing.expectEqual(@as(usize, 2), versions.items.len);
    try std.testing.expectEqualStrings("575.64.05", versions.items[0]);
    try std.testing.expectEqualStrings("580.126.18", versions.items[1]);
}

test "latest shared version ignores platform-only newer versions" {
    const x86 = [_][]const u8{ "580.126.18", "595.71.05", "600.1" };
    const aarch = [_][]const u8{ "580.126.18", "595.71.05" };
    const latest = (try findLatestShared(&x86, &aarch)).?;
    try std.testing.expectEqualStrings("595.71.05", latest);
}
