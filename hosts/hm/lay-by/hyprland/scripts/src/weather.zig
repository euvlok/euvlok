const std = @import("std");

const Config = struct {
    api: []const u8,
    key: []const u8,
    city: []const u8,
    units: []const u8,
    symbol: []const u8,
};

const config: Config = .{
    .api = "https://api.openweathermap.org/data/2.5",
    .key = "a78c793d7f2431574ca9c5f56e74fc9b",
    .city = "4701458",
    .units = "imperial",
    .symbol = "°",
};

const nf_weather_day_sunny = "\u{e30d} ";
const nf_weather_day_cloudy = "\u{e302} ";
const nf_weather_cloud = "\u{e33d} ";
const nf_weather_cloudy = "\u{e312} ";
const nf_weather_hail = "\u{e314} ";
const nf_weather_day_hail = "\u{e304} ";
const nf_weather_night_alt_rain_wind = "\u{e324} ";
const nf_weather_lightning = "\u{e315} ";
const nf_weather_snowflake_cold = "\u{e36f} ";
const nf_weather_dust = "\u{e35d} ";
const nf_fa_xmark = "\u{f00d}\t";

const IconRule = struct {
    match: Match,
    icon: []const u8,

    const Match = union(enum) {
        exact: []const u8,
        prefix: []const u8,

        fn matches(match: Match, code: []const u8) bool {
            return switch (match) {
                .exact => |expected| std.mem.eql(u8, code, expected),
                .prefix => |expected_prefix| std.mem.startsWith(u8, code, expected_prefix),
            };
        }
    };
};

fn exact(code: []const u8, icon: []const u8) IconRule {
    return .{ .match = .{ .exact = code }, .icon = icon };
}

fn prefix(code: []const u8, icon: []const u8) IconRule {
    return .{ .match = .{ .prefix = code }, .icon = icon };
}

const icon_rules = [_]IconRule{
    exact("01d", nf_weather_day_sunny),
    exact("01n", nf_weather_day_sunny),
    exact("02d", nf_weather_day_cloudy),
    exact("02n", nf_weather_day_cloudy),
    prefix("03", nf_weather_cloud),
    prefix("04", nf_weather_cloudy),
    exact("09d", nf_weather_hail),
    exact("09n", nf_weather_hail),
    exact("10d", nf_weather_day_hail),
    exact("10n", nf_weather_night_alt_rain_wind),
    exact("11d", nf_weather_lightning),
    exact("11n", nf_weather_lightning),
    exact("13d", nf_weather_snowflake_cold),
    exact("13n", nf_weather_snowflake_cold),
    exact("50d", nf_weather_dust),
    exact("50n", nf_weather_dust),
};

const WeatherResponse = struct {
    weather: []const Weather,
    main: Main,

    const Weather = struct {
        description: []const u8,
        icon: []const u8,
    };

    const Main = struct {
        temp: f64,
    };
};

fn iconFor(code: []const u8) []const u8 {
    for (icon_rules) |rule| {
        if (rule.match.matches(code)) return rule.icon;
    }

    return nf_fa_xmark;
}

fn cityParam(allocator: std.mem.Allocator, city: []const u8) ![]u8 {
    if (std.fmt.parseInt(u64, city, 10)) |_| {
        return std.fmt.allocPrint(allocator, "id={s}", .{city});
    } else |_| {
        return std.fmt.allocPrint(allocator, "q={s}", .{city});
    }
}

fn fetchWeather(io: std.Io, allocator: std.mem.Allocator, url: []const u8) ![]u8 {
    var client: std.http.Client = .{
        .allocator = allocator,
        .io = io,
    };
    defer client.deinit();

    var body: std.Io.Writer.Allocating = .init(allocator);
    errdefer body.deinit();

    const result = client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &body.writer,
    }) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return error.OpenWeatherRequestFailed,
    };
    if (result.status != .ok) {
        body.deinit();
        return error.OpenWeatherRequestFailed;
    }

    return body.toOwnedSlice();
}

fn tempToInt(temp: f64) !i64 {
    const min = @as(f64, @floatFromInt(std.math.minInt(i64)));
    const max = @as(f64, @floatFromInt(std.math.maxInt(i64)));

    if (!std.math.isFinite(temp) or temp < min or temp > max) {
        return error.OpenWeatherResponseInvalid;
    }

    return @intFromFloat(temp);
}

fn renderWeather(allocator: std.mem.Allocator, body: []const u8, symbol: []const u8) !?[]u8 {
    var parsed = std.json.parseFromSlice(WeatherResponse, allocator, body, .{
        .ignore_unknown_fields = true,
    }) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return error.OpenWeatherResponseInvalid,
    };
    defer parsed.deinit();

    if (parsed.value.weather.len == 0) return null;

    const current = parsed.value.weather[0];
    const temp_int = try tempToInt(parsed.value.main.temp);

    return try std.fmt.allocPrint(allocator, "{s} {s}, {d}{s}", .{
        iconFor(current.icon),
        current.description,
        temp_int,
        symbol,
    });
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const city_param = try cityParam(allocator, config.city);
    defer allocator.free(city_param);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/weather?appid={s}&{s}&units={s}",
        .{ config.api, config.key, city_param, config.units },
    );
    defer allocator.free(url);

    const body = fetchWeather(init.io, allocator, url) catch |err| switch (err) {
        error.OpenWeatherRequestFailed => return,
        else => |unexpected| return unexpected,
    };
    defer allocator.free(body);

    const text = renderWeather(allocator, body, config.symbol) catch |err| switch (err) {
        error.OpenWeatherResponseInvalid => return,
        else => |unexpected| return unexpected,
    };
    const output = text orelse return;
    defer allocator.free(output);

    var buffer: [256]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    try stdout.interface.print("{s}\n", .{output});
    try stdout.interface.flush();
}

test "iconFor handles exact prefix and fallback rules" {
    try std.testing.expectEqualStrings(nf_weather_day_sunny, iconFor("01d"));
    try std.testing.expectEqualStrings(nf_weather_cloud, iconFor("03n"));
    try std.testing.expectEqualStrings(nf_fa_xmark, iconFor("99x"));
}

test "cityParam selects id for numeric cities and q otherwise" {
    const allocator = std.testing.allocator;

    const by_id = try cityParam(allocator, "4701458");
    defer allocator.free(by_id);
    try std.testing.expectEqualStrings("id=4701458", by_id);

    const by_name = try cityParam(allocator, "Sofia");
    defer allocator.free(by_name);
    try std.testing.expectEqualStrings("q=Sofia", by_name);
}

test "renderWeather formats valid weather responses" {
    const allocator = std.testing.allocator;
    const body =
        \\{
        \\  "weather": [{"description": "clear sky", "icon": "01d"}],
        \\  "main": {"temp": 72.9}
        \\}
    ;

    const text = (try renderWeather(allocator, body, "°")).?;
    defer allocator.free(text);
    try std.testing.expectEqualStrings(nf_weather_day_sunny ++ " clear sky, 72°", text);
}

test "tempToInt rejects non-finite and out-of-range temperatures" {
    try std.testing.expectEqual(@as(i64, 72), try tempToInt(72.9));
    try std.testing.expectError(error.OpenWeatherResponseInvalid, tempToInt(std.math.inf(f64)));
    try std.testing.expectError(error.OpenWeatherResponseInvalid, tempToInt(-std.math.inf(f64)));
}

test "renderWeather treats malformed responses as an expected weather error" {
    try std.testing.expectError(
        error.OpenWeatherResponseInvalid,
        renderWeather(std.testing.allocator, "not json", "°"),
    );

    const empty_weather =
        \\{
        \\  "weather": [],
        \\  "main": {"temp": 72.9}
        \\}
    ;
    try std.testing.expect((try renderWeather(std.testing.allocator, empty_weather, "°")) == null);
}

test "renderWeather treats missing required fields as an expected weather error" {
    const missing_main =
        \\{
        \\  "weather": [{"description": "clear sky", "icon": "01d"}]
        \\}
    ;
    try std.testing.expectError(
        error.OpenWeatherResponseInvalid,
        renderWeather(std.testing.allocator, missing_main, "°"),
    );

    const missing_icon =
        \\{
        \\  "weather": [{"description": "clear sky"}],
        \\  "main": {"temp": 72.9}
        \\}
    ;
    try std.testing.expectError(
        error.OpenWeatherResponseInvalid,
        renderWeather(std.testing.allocator, missing_icon, "°"),
    );
}
