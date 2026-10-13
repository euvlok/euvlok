{ lib, ... }: {
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 14;
        modules-left = [
          "hyprland/workspaces"
          "custom/weather"
        ];
        modules-center = [ "custom/music" ];
        modules-right = [
          "network"
          "battery"
          "cpu"
          "memory"
          "tray"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            default = " ";
            active = " ";
            urgent = " ";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };
        network = {
          interval = 5;
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          tooltip-format = "{ifname}: {ipaddr}";
        };
        battery = {
          interval = 15;
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };
        cpu = {
          interval = 2;
          format = " {usage:2}%";
        };
        memory = {
          interval = 2;
          format = " {}%";
        };
        tray.spacing = 8;
        clock = {
          format = " {:L%I:%M %p}";
          tooltip = true;
          tooltip-format = "<big>{:%A, %d %B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };
        "custom/music" = {
          format = "󰎇 {}";
          interval = 2;
          on-click = "playerctl play-pause";
          exec = lib.trivial.readFile ../../hyprland/scripts/music.sh;
        };
        "custom/weather" = {
          interval = 900;
          exec = lib.trivial.readFile ../../hyprland/scripts/weather.sh;
        };
      }
    ];
    style = lib.trivial.readFile ../../hyprland/waybar.css;
  };
}
