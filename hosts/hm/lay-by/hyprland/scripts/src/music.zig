const std = @import("std");

const players = [_][]const u8{ "spotify", "rhythmbox", "Feishin" };
const no_player_message = "No Player Found\n";

const MetadataField = enum {
    artist,
    title,
};

const MetadataRule = struct {
    key: []const u8,
    field: MetadataField,
};

const metadata_rules = [_]MetadataRule{
    .{ .key = "xesam:artist", .field = .artist },
    .{ .key = "xesam:title", .field = .title },
};

const MetadataValue = struct {
    field: MetadataField,
    value: []const u8,
};

const TrackText = struct {
    artists: std.ArrayList([]const u8) = .empty,
    titles: std.ArrayList([]const u8) = .empty,

    fn deinit(self: *TrackText, allocator: std.mem.Allocator) void {
        self.artists.deinit(allocator);
        self.titles.deinit(allocator);
    }

    fn append(self: *TrackText, allocator: std.mem.Allocator, item: MetadataValue) !void {
        switch (item.field) {
            .artist => try self.artists.append(allocator, item.value),
            .title => try self.titles.append(allocator, item.value),
        }
    }

    fn isEmpty(self: TrackText) bool {
        return self.artists.items.len == 0 and self.titles.items.len == 0;
    }

    fn writeJoined(values: []const []const u8, allocator: std.mem.Allocator, out: *std.ArrayList(u8)) !void {
        for (values, 0..) |value, index| {
            if (index != 0) try out.append(allocator, '\n');
            try out.appendSlice(allocator, value);
        }
    }

    fn format(self: TrackText, allocator: std.mem.Allocator) ![]u8 {
        var out = std.ArrayList(u8).empty;
        defer out.deinit(allocator);

        try writeJoined(self.artists.items, allocator, &out);
        if (self.artists.items.len != 0 and self.titles.items.len != 0) {
            try out.appendSlice(allocator, " - ");
        }
        try writeJoined(self.titles.items, allocator, &out);

        return collapseSpaces(allocator, out.items);
    }
};

fn writeNoPlayer(io: std.Io) !void {
    try std.Io.File.stdout().writeStreamingAll(io, no_player_message);
}

fn isWantedPlayer(line: []const u8) bool {
    for (players) |player| {
        if (std.mem.indexOf(u8, line, player) != null) return true;
    }
    return false;
}

fn readMetadata(line: []const u8) ?MetadataValue {
    for (metadata_rules) |rule| {
        if (std.mem.indexOf(u8, line, rule.key)) |key_start| {
            const value_start = key_start + rule.key.len;
            return .{
                .field = rule.field,
                .value = std.mem.trim(u8, line[value_start..], " \t"),
            };
        }
    }

    return null;
}

fn collapseSpaces(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var out = std.ArrayList(u8).empty;
    var previous_space = false;
    defer out.deinit(allocator);

    for (std.mem.trim(u8, text, " \t\r\n")) |byte| {
        const is_space = byte == ' ' or byte == '\t' or byte == '\r' or byte == '\n';
        if (is_space) {
            if (!previous_space) try out.append(allocator, ' ');
            previous_space = true;
        } else {
            try out.append(allocator, byte);
            previous_space = false;
        }
    }

    return out.toOwnedSlice(allocator);
}

fn renderTrackText(allocator: std.mem.Allocator, metadata: []const u8) !?[]u8 {
    var track: TrackText = .{};
    defer track.deinit(allocator);

    var lines = std.mem.splitScalar(u8, metadata, '\n');
    while (lines.next()) |line| {
        if (!isWantedPlayer(line)) continue;
        if (readMetadata(line)) |item| try track.append(allocator, item);
    }
    if (track.isEmpty()) return null;

    return try track.format(allocator);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const result = std.process.run(allocator, init.io, .{
        .argv = &.{ "playerctl", "-a", "metadata" },
    }) catch |err| switch (err) {
        error.FileNotFound, error.AccessDenied => {
            try writeNoPlayer(init.io);
            return;
        },
        else => |unexpected| return unexpected,
    };
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    switch (result.term) {
        .exited => |code| if (code != 0) {
            try writeNoPlayer(init.io);
            return;
        },
        else => {
            try writeNoPlayer(init.io);
            return;
        },
    }

    const maybe_compact = try renderTrackText(allocator, result.stdout);
    const compact = maybe_compact orelse {
        try writeNoPlayer(init.io);
        return;
    };
    defer allocator.free(compact);

    var buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    try stdout.interface.print("{s}\n", .{compact});
    try stdout.interface.flush();
}

test "collapseSpaces trims and compacts whitespace" {
    const allocator = std.testing.allocator;
    const compact = try collapseSpaces(allocator, " \tArtist\n\n  Song \r\n");
    defer allocator.free(compact);

    try std.testing.expectEqualStrings("Artist Song", compact);
}

test "readMetadata extracts known metadata values" {
    const artist = readMetadata("spotify xesam:artist   The Artist").?;
    try std.testing.expectEqual(MetadataField.artist, artist.field);
    try std.testing.expectEqualStrings("The Artist", artist.value);

    const title = readMetadata("Feishin xesam:title Track Name").?;
    try std.testing.expectEqual(MetadataField.title, title.field);
    try std.testing.expectEqualStrings("Track Name", title.value);

    try std.testing.expect(readMetadata("spotify mpris:length 123") == null);
}

test "TrackText formats complete and partial metadata" {
    const allocator = std.testing.allocator;

    var complete: TrackText = .{};
    defer complete.deinit(allocator);
    try complete.append(allocator, .{ .field = .artist, .value = "Artist" });
    try complete.append(allocator, .{ .field = .title, .value = "Song" });
    const complete_text = try complete.format(allocator);
    defer allocator.free(complete_text);
    try std.testing.expectEqualStrings("Artist - Song", complete_text);

    var title_only: TrackText = .{};
    defer title_only.deinit(allocator);
    try title_only.append(allocator, .{ .field = .title, .value = "Song" });
    const title_text = try title_only.format(allocator);
    defer allocator.free(title_text);
    try std.testing.expectEqualStrings("Song", title_text);

    const empty: TrackText = .{};
    try std.testing.expect(empty.isEmpty());
}

test "renderTrackText ignores unrelated players and reports empty metadata" {
    const allocator = std.testing.allocator;

    const ignored =
        \\firefox xesam:artist Browser
        \\vlc mpris:length 123
    ;
    try std.testing.expect((try renderTrackText(allocator, ignored)) == null);

    const rendered = (try renderTrackText(
        allocator,
        "spotify xesam:artist Artist\nspotify xesam:title   Song\n",
    )).?;
    defer allocator.free(rendered);
    try std.testing.expectEqualStrings("Artist - Song", rendered);
}
