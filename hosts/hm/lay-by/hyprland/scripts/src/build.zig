const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run unit tests");

    addScript(b, test_step, target, optimize, "lay-by-waybar-weather", "weather.zig");
    addScript(b, test_step, target, optimize, "lay-by-waybar-nvidia", "nvidia.zig");
    addScript(b, test_step, target, optimize, "lay-by-waybar-music", "music.zig");
}

fn addScript(
    b: *std.Build,
    test_step: *std.Build.Step,
    target: anytype,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    source: []const u8,
) void {
    const module = b.createModule(.{
        .root_source_file = b.path(source),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = module,
    });
    b.installArtifact(exe);

    const unit_tests = b.addTest(.{
        .root_module = module,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
