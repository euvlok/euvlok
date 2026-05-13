const std = @import("std");

const ChezMoiScript = struct {
    name: []const u8,
    path: []const u8,
};

const chezmoi_scripts = [_]ChezMoiScript{
    .{
        .name = "run_once_zed_install_catppuccin_theme",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_once_zed_install_catppuccin_theme.zig",
    },
    .{
        .name = "run_onchange_after_install-vs-extensions",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_onchange_after_install-vs-extensions.zig",
    },
    .{
        .name = "run_onchange_after_nushell_init",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_onchange_after_nushell_init.zig",
    },
    .{
        .name = "run_onchange_after_raycast_window_management",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_onchange_after_raycast_window_management.zig",
    },
    .{
        .name = "run_onchange_after_yazi_init",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_onchange_after_yazi_init.zig",
    },
    .{
        .name = "run_onchange_after_zsh_bash_init",
        .path = "dotfiles/flameflag/.chezmoiscripts/run_onchange_after_zsh_bash_init.zig",
    },
};

const waybar_scripts = [_]ChezMoiScript{
    .{ .name = "lay-by-waybar-weather", .path = "hosts/hm/lay-by/hyprland/scripts/src/weather.zig" },
    .{ .name = "lay-by-waybar-nvidia", .path = "hosts/hm/lay-by/hyprland/scripts/src/nvidia.zig" },
    .{ .name = "lay-by-waybar-music", .path = "hosts/hm/lay-by/hyprland/scripts/src/music.zig" },
};

const packages = [_]ChezMoiScript{
    .{ .name = "nvidia-prefetch", .path = "packages/nvidia-prefetch/src/main.zig" },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const check_step = b.step("check", "Compile Zig scripts without installing them");
    const test_step = b.step("test", "Run Zig unit tests");

    const chezmoi = b.createModule(.{
        .root_source_file = b.path("lib/zig/chezmoi/script.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const chezmoi_tests = b.addTest(.{
        .root_module = chezmoi,
    });
    test_step.dependOn(&b.addRunArtifact(chezmoi_tests).step);

    for (chezmoi_scripts) |script| {
        addScript(b, check_step, test_step, target, optimize, script, chezmoi, false);
    }

    for (waybar_scripts) |script| {
        addScript(b, check_step, test_step, target, optimize, script, null, false);
    }

    for (packages) |script| {
        addScript(b, check_step, test_step, target, optimize, script, null, true);
    }
}

fn addScript(
    b: *std.Build,
    check_step: *std.Build.Step,
    test_step: *std.Build.Step,
    target: anytype,
    optimize: std.builtin.OptimizeMode,
    script: ChezMoiScript,
    chezmoi: ?*std.Build.Module,
    install: bool,
) void {
    const module = b.createModule(.{
        .root_source_file = b.path(script.path),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (chezmoi) |dependency| module.addImport("chezmoi", dependency);

    const exe = b.addExecutable(.{
        .name = script.name,
        .root_module = module,
    });
    if (install) b.installArtifact(exe);
    check_step.dependOn(&exe.step);

    const unit_tests = b.addTest(.{
        .root_module = module,
    });
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
