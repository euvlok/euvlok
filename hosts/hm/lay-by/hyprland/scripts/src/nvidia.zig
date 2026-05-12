const std = @import("std");

const threshold = 76;

const GpuMetric = struct {
    query: []const u8,
};

const metrics = struct {
    const temperature: GpuMetric = .{ .query = "--query-gpu=temperature.gpu" };
    const utilization: GpuMetric = .{ .query = "--query-gpu=utilization.gpu" };
};

const GpuStatus = struct {
    utilization_raw: []u8,
    temperature: i64,

    fn deinit(self: GpuStatus, allocator: std.mem.Allocator) void {
        allocator.free(self.utilization_raw);
    }

    fn utilization(self: GpuStatus) []const u8 {
        return std.mem.trim(u8, self.utilization_raw, " \t\r\n");
    }
};

fn formatGpuStatus(allocator: std.mem.Allocator, utilization: []const u8, temperature: i64) ![]u8 {
    if (temperature > threshold) {
        return std.fmt.allocPrint(allocator, "{s} %{{F#FE3120}}{d}°C", .{ utilization, temperature });
    }

    return std.fmt.allocPrint(allocator, "{s}% {d}°C", .{ utilization, temperature });
}

fn queryMetric(io: std.Io, allocator: std.mem.Allocator, metric: GpuMetric) ![]u8 {
    const result = try std.process.run(allocator, io, .{
        .argv = &.{
            "nvidia-smi",
            metric.query,
            "--format=csv,noheader,nounits",
        },
    });
    defer allocator.free(result.stderr);

    const ok = switch (result.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (ok) return result.stdout;

    allocator.free(result.stdout);
    return error.NvidiaSmiFailed;
}

fn parseGpuStatus(allocator: std.mem.Allocator, temp_raw: []const u8, utilization_raw: []const u8) !GpuStatus {
    const temp_text = std.mem.trim(u8, temp_raw, " \t\r\n");
    const temperature = std.fmt.parseInt(i64, temp_text, 10) catch return error.NvidiaSmiFailed;
    const utilization_owned = try allocator.dupe(u8, utilization_raw);

    return .{
        .utilization_raw = utilization_owned,
        .temperature = temperature,
    };
}

fn readGpuStatus(io: std.Io, allocator: std.mem.Allocator) !GpuStatus {
    const temp_raw = try queryMetric(io, allocator, metrics.temperature);
    defer allocator.free(temp_raw);

    const utilization_raw = try queryMetric(io, allocator, metrics.utilization);
    defer allocator.free(utilization_raw);

    return try parseGpuStatus(allocator, temp_raw, utilization_raw);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const status = readGpuStatus(init.io, allocator) catch |err| switch (err) {
        error.NvidiaSmiFailed, error.FileNotFound, error.AccessDenied => return,
        else => |unexpected| return unexpected,
    };
    defer status.deinit(allocator);

    const text = try formatGpuStatus(allocator, status.utilization(), status.temperature);
    defer allocator.free(text);

    var buffer: [128]u8 = undefined;
    var stdout = std.Io.File.stdout().writerStreaming(init.io, &buffer);

    try stdout.interface.print("{s}\n", .{text});
    try stdout.interface.flush();
}

test "formatGpuStatus marks hot temperatures" {
    const allocator = std.testing.allocator;

    const cool = try formatGpuStatus(allocator, "42", 76);
    defer allocator.free(cool);
    try std.testing.expectEqualStrings("42% 76°C", cool);

    const hot = try formatGpuStatus(allocator, "88", 77);
    defer allocator.free(hot);
    try std.testing.expectEqualStrings("88 %{F#FE3120}77°C", hot);
}

test "GpuStatus trims utilization output" {
    const allocator = std.testing.allocator;
    const utilization_raw = try allocator.dupe(u8, "  35 \n");
    const status: GpuStatus = .{
        .utilization_raw = utilization_raw,
        .temperature = 40,
    };
    defer status.deinit(allocator);

    try std.testing.expectEqualStrings("35", status.utilization());
}

test "parseGpuStatus maps invalid temperature output to expected nvidia error" {
    const allocator = std.testing.allocator;

    const status = try parseGpuStatus(allocator, "  64\n", "  35 \n");
    defer status.deinit(allocator);
    try std.testing.expectEqual(@as(i64, 64), status.temperature);
    try std.testing.expectEqualStrings("35", status.utilization());

    try std.testing.expectError(error.NvidiaSmiFailed, parseGpuStatus(allocator, "not-a-temp", "35"));
}
