{ config, lib, ... }:
{
  programs.niri.settings.binds =
    with config.lib.niri.actions;
    let
      mkBinds =
        {
          prefix,
          action,
          range ? lib.range 1 9,
        }:
        range
        |> map (num: {
          name = "${prefix}${toString num}";
          value = {
            action = action num;
          };
        })
        |> lib.listToAttrs;

      mkDirectionalBinds =
        { prefix, actions }:
        lib.mkMerge [
          {
            "${prefix}Left".action = actions.left;
            "${prefix}Down".action = actions.down;
            "${prefix}Up".action = actions.up;
            "${prefix}Right".action = actions.right;
          }
          {
            "${prefix}H".action = actions.left;
            "${prefix}J".action = actions.down;
            "${prefix}K".action = actions.up;
            "${prefix}L".action = actions.right;
          }
        ];

      mkWheelBinds =
        { prefix, actions }:
        {
          "${prefix}WheelScrollDown".action = actions.down;
          "${prefix}WheelScrollUp".action = actions.up;
          "${prefix}WheelScrollRight".action = actions.right;
          "${prefix}WheelScrollLeft".action = actions.left;
        };

      # Group bindings by functionality
      workspaceBindings = lib.mkMerge [
        # Numbered workspace bindings
        (mkBinds {
          prefix = "Mod+";
          action = focus-workspace;
        })
        (mkBinds {
          prefix = "Mod+Ctrl+";
          action = move-column-to-workspace;
        })

        # Workspace navigation
        {
          "Mod+Page_Down".action = focus-workspace-down;
          "Mod+Page_Up".action = focus-workspace-up;
          "Mod+U".action = focus-workspace-down;
          "Mod+I".action = focus-workspace-up;
          "Mod+Tab".action = focus-workspace-previous;

          "Mod+Shift+Page_Down".action = move-workspace-down;
          "Mod+Shift+Page_Up".action = move-workspace-up;
          "Mod+Shift+U".action = move-workspace-down;
          "Mod+Shift+I".action = move-workspace-up;

          "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
          "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
          "Mod+Ctrl+U".action = move-column-to-workspace-down;
          "Mod+Ctrl+I".action = move-column-to-workspace-up;
        }
      ];

      focusAndMovementBindings = lib.mkMerge [
        # Focus direction
        (mkDirectionalBinds {
          prefix = "Mod+";
          actions = {
            left = focus-column-left;
            down = focus-window-down;
            up = focus-window-up;
            right = focus-column-right;
          };
        })

        # Move window/column
        (mkDirectionalBinds {
          prefix = "Mod+Ctrl+";
          actions = {
            left = move-column-left;
            down = move-window-down;
            up = move-window-up;
            right = move-column-right;
          };
        })

        # Move to monitor
        (mkDirectionalBinds {
          prefix = "Mod+Shift+Ctrl+";
          actions = {
            left = move-column-to-monitor-left;
            down = move-column-to-monitor-down;
            up = move-column-to-monitor-up;
            right = move-column-to-monitor-right;
          };
        })

        # Wheel scroll bindings
        (mkWheelBinds {
          prefix = "Mod+";
          actions = {
            down = focus-workspace-down;
            up = focus-workspace-up;
            right = focus-column-right;
            left = focus-column-left;
          };
        })

        # First/last navigation
        {
          "Mod+Home".action = focus-column-first;
          "Mod+End".action = focus-column-last;
          "Mod+Ctrl+Home".action = move-column-to-first;
          "Mod+Ctrl+End".action = move-column-to-last;
        }
      ];

      mediaControls = {
        "XF86AudioRaiseVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+";
        "XF86AudioLowerVolume".action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
        "XF86AudioMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
        "XF86AudioMicMute".action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
        "XF86MonBrightnessUp".action = spawn "light" "-T" "1.1";
        "XF86MonBrightnessDown".action = spawn "light" "-T" "0.9";
      };

      windowLayoutBindings = {
        "Mod+Q".action = close-window;
        "Mod+BracketLeft".action = consume-or-expel-window-left;
        "Mod+BracketRight".action = consume-or-expel-window-right;
        "Mod+Comma".action = consume-window-into-column;
        "Mod+Period".action = expel-window-from-column;

        # Column and window size
        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+Ctrl+R".action = reset-window-height;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+Ctrl+F".action = expand-column-to-available-width;
        "Mod+C".action = center-column;
        "Mod+Minus".action = set-column-width "-2%";
        "Mod+Equal".action = set-column-width "+2%";
        "Mod+Shift+Minus".action = set-window-height "-2%";
        "Mod+Shift+Equal".action = set-window-height "+2%";

        # Window modes
        "Mod+V".action = toggle-window-floating;
        "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
        "Mod+W".action = toggle-column-tabbed-display;
      };

      systemControls = {
        "Print".action = screenshot;
        "Ctrl+Print".action = {
          screenshot-screen = {
            write-to-disk = true;
          };
        };
        "Alt+Print".action = screenshot-window;
        "Mod+Escape".action = toggle-keyboard-shortcuts-inhibit;
        "Mod+Shift+E".action = quit;
        "Ctrl+Alt+Delete".action = quit;
      };

      misc = {
        "Mod+Shift+Slash".action = show-hotkey-overlay;
      };
    in
    lib.mkMerge [
      workspaceBindings
      focusAndMovementBindings
      mediaControls
      windowLayoutBindings
      systemControls
      misc
    ];
}
