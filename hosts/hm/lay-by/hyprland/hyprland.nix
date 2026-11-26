{ pkgs, ... }:
{
  services.hyprpolkitagent.enable = true;
  # Preserve the packaged agent's Wayland guard and service lifecycle
  systemd.user.services.hyprpolkitagent = {
    Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
    Service = {
      Slice = "session.slice";
      TimeoutStopSec = "5sec";
      Restart = "on-failure";
    };
  };

  services.wlsunset = {
    enable = true;
    package = pkgs.unstable.wlsunset;
    sunrise = "7:00";
    sunset = "21:00";
    systemdTarget = "hyprland-session.target";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 2 })
    hl.monitor({ output = "Unknown-1", disabled = true })
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080", position = "0x0", scale = 1 })
    hl.monitor({ output = "DP-1", mode = "2560x1080@200", position = "1920x0", scale = 1, vrr = 2 })

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_THEME", "BreezeX-Dark")

    hl.on("hyprland.start", function()
      hl.exec_cmd("waybar")
      hl.exec_cmd("hyprctl setcursor BreezeX-Dark 24")
      hl.exec_cmd("xrandr --output DP-1 --primary")
      hl.exec_cmd("keepassxc --minimized")
    end)

    hl.config({
      render = { direct_scanout = 1 },
      cursor = { no_hardware_cursors = 2 },
      misc = { vrr = 2 },
      general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
      },
      decoration = {
        rounding = 5,
        active_opacity = 0.8,
        inactive_opacity = 0.8,
        blur = {
          enabled = true,
          size = 8,
          passes = 2,
          ignore_opacity = true,
          vibrancy = 0.1606,
          new_optimizations = true,
        },
      },
      animations = { enabled = true },
      input = { follow_mouse = 2 },
    })

    hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.05, 1.05} } })
    hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "myBezier" })
    hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "default", style = "popin 80%" })
    for _, leaf in ipairs({ "border", "borderangle", "fade", "workspaces" }) do
      hl.animation({ leaf = leaf, enabled = true, speed = 2, bezier = "default" })
    end

    local mainMod = "SUPER"
    local terminal = "alacritty"
    local fileManager = "thunar"

    hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("rofi -show drun"))
    hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal))
    hl.bind("ALT + 1", hl.dsp.window.close())
    hl.bind(mainMod .. " + M", hl.dsp.exit())
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
    hl.bind(mainMod .. " + S", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

    for _, direction in ipairs({ "left", "right", "up", "down" }) do
      hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    end
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock"))
    hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
    hl.bind("CTRL + Print", hl.dsp.exec_cmd("wl-paste | swappy -f -"))
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

    -- KP_1 through KP_3 use keycodes so they work with either Num Lock state.
    hl.bind("code:87", hl.dsp.exec_cmd("playerctl previous"))
    hl.bind("code:88", hl.dsp.exec_cmd("playerctl play-pause"))
    hl.bind("code:89", hl.dsp.exec_cmd("playerctl next"))

    hl.bind("Control_R", hl.dsp.global("discord:discord-toggle-mute"))

    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.window_rule({ name = "lay-by-suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
    hl.window_rule({
      name = "lay-by-fullscreen-direct-scanout",
      match = { fullscreen = true },
      opacity = "1.0 override 1.0 override 1.0 override",
      no_blur = true,
      no_shadow = true,
      no_anim = true,
      rounding = 0,
    })
    hl.layer_rule({ name = "lay-by-waybar-blur", match = { namespace = "waybar" }, blur = true })
  '';
}
