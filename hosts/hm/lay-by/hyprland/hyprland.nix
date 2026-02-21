_: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      ",preferred,auto,auto, vrr, 1"
      "Unknown-1, disable"
      "HDMI-A-1, 1920x1080, 0x0, 1"
      "DP-1, 2560x1080@200, 1920x0, 1"
    ];

    env = [
      "XCURSOR_SIZE,24"
      "HYPRCURSOR_SIZE,24"
      "HYPRCURSOR_THEME,BreezeX-Dark"
    ];

    exec-once = [
      "waybar"
      "hyprctl setcursor BreezeX-Dark 24"
      "easyeffects -w"
      "wlsunset -S 9:00 -s 21:00"
      "systemctl --user start hyprpolkitagent"
      "xrandr --output DP-1 --primary"
      "nicotine -s"
    ];

    general = {
      gaps_in = 1;
      gaps_out = 2;
      border_size = 1;

      # Set to true enable resizing windows by clicking and dragging on borders and gaps
      resize_on_border = false;

      # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
      allow_tearing = true;

      layout = "dwindle";
    };

    decoration = {
      rounding = 5;

      # Change transparency of focused and unfocused windows
      active_opacity = 0.8;
      inactive_opacity = 0.8;

      # drop_shadow = true;

      # https://wiki.hyprland.org/Configuring/Variables/#blur
      blur = {
        enabled = true;
        size = 8;
        passes = 2;
        ignore_opacity = true;
        vibrancy = 0.1606;
        new_optimizations = false;
      };
    };

    animations = {
      enabled = true;

      # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

      bezier = "myBezier, 0.05, 0.9, 0.05, 1.05";

      animation = [
        "windows, 1, 2, myBezier"
        "windowsOut, 1, 2, default, popin 80%"
        "border, 1, 2, default"
        "borderangle, 1, 2, default"
        "fade, 1, 2, default"
        "workspaces, 1, 2, default"
      ];
    };

    "$mainMod" = "SUPER";
    "$terminal" = "alacritty";
    "$fileManager" = "thunar";

    bind = [
      "$mainMod, Space, exec, rofi -show drun "
      "$Control_L&Alt_L, T, exec, $terminal"
      "$Alt_L, 1, killactive,"
      "$mainMod, M, exit,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, S, togglefloating,"
      "$mainMod, P, pseudo," # dwindle
      "$mainMod, J, togglesplit," # dwindle

      # Move focus with mainMod + arrow keys
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Scroll through existing workspaces with mainMod + scroll
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"

      # hyprlock keybind
      "Control_L&Alt_L, L, exec, hyprlock"

      # Screenshot bind
      ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"

      # Edit image currently in clipboard
      "Control_L, Print, exec, wl-paste | swappy -f -"

      "$mainMod, F, fullscreen"

      # Discord mute keybind
      ", Control_r, focuswindow, class:^discord$"
      ", Control_r, sendshortcut, Control_L&SHIFT, M, class:^discord$"
      ", Control_r, focuscurrentorlast"
    ];

    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    windowrulev2 = [
      "suppressevent maximize, class:.*"
      "immediate, class:^(Titanfall2.exe)$"
      "immediate, class:^(helldivers2.exe)$"
      "fullscreenstate 2 0, class:^(cs2)$"
      "immediate, class:^(*.exe)$"
    ];

    layerrule = [
      "blur,waybar"
    ];

    input.follow_mouse = 2;
  };
}
