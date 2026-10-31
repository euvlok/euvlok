_: {
  wayland.windowManager.hyprland.extraConfig = ''
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto", vrr = 1 })
    hl.monitor({ output = "Unknown-1", disabled = true })
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080", position = "0x0", scale = 1 })
    hl.monitor({ output = "DP-1", mode = "2560x1080@200", position = "1920x0", scale = 1 })

    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_THEME", "BreezeX-Dark")

    hl.on("hyprland.start", function()
      hl.exec_cmd("waybar")
      hl.exec_cmd("hyprctl setcursor BreezeX-Dark 24")
      hl.exec_cmd("wlsunset -S 7:00 -s 21:00")
      hl.exec_cmd("systemctl --user start hyprpolkitagent")
      hl.exec_cmd("xrandr --output DP-1 --primary")
      hl.exec_cmd("keepassxc --minimized")
    end)

    hl.config({
      general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 1,
        resize_on_border = false,
        allow_tearing = true,
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
          new_optimizations = false,
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

    -- Focus Discord, send mute, then restore focus, in that order.
    hl.bind("Control_R", function()
      hl.dispatch(hl.dsp.focus({ window = "class:^discord$" }))
      hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL + SHIFT", key = "M", window = "class:^discord$" }))
      hl.dispatch(hl.dsp.focus({ last = true }))
    end)

    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.window_rule({ name = "lay-by-suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
    hl.window_rule({ name = "lay-by-titanfall2-immediate", match = { class = "^(Titanfall2.exe)$" }, immediate = true })
    hl.window_rule({ name = "lay-by-helldivers2-immediate", match = { class = "^(helldivers2.exe)$" }, immediate = true })
    hl.window_rule({ name = "lay-by-cs2-fullscreen", match = { class = "^(cs2)$" }, fullscreen_state = "2 0" })
    hl.window_rule({ name = "lay-by-exe-immediate", match = { class = [[^.*\.exe$]] }, immediate = true })
    hl.layer_rule({ name = "lay-by-waybar-blur", match = { namespace = "waybar" }, blur = true })
  '';
}
