{ lib, pkgs, ... }:
let
  nvidiaStatus = pkgs.writeShellApplication {
    name = "waybar-nvidia-status";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      if [ -e "$runtime_dir/gamemode-active" ]; then
        printf 'GM\n'
        exit 0
      fi

      if ! command -v nvidia-smi >/dev/null 2>&1; then
        exit 0
      fi

      if ! stats="$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader,nounits 2>/dev/null)"; then
        exit 0
      fi

      IFS=',' read -r temp gpu <<<"$stats"
      temp="''${temp//[[:space:]]/}"
      gpu="''${gpu//[[:space:]]/}"
      threshold=76

      if ((temp > threshold)); then
        printf '%s %%{F#FE3120}%s°C\n' "$gpu" "$temp"
      else
        printf '%s%% %s°C\n' "$gpu" "$temp"
      fi
    '';
  };
in
{
  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      layer = "top";
      position = "top";
      modules-center = [ "custom/music" ];
      modules-left = [
        "hyprland/workspaces"
        "custom/weather"
      ];
      modules-right = [
        "custom/nvidia"
        "cpu"
        "memory"
        "clock"
      ];

      height = 14;

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
      "clock" = {
        format = " {:L%I:%M %p}";
        tooltip = true;
        tooltip-format = "<big>{:%A, %d.%B %Y }</big>\n<tt><small>{calendar}</small></tt>";
      };
      "hyprland/window" = {
        max-length = 22;
        separate-outputs = false;
      };
      "memory" = {
        interval = 1;
        format = " {}%";
        tooltip = true;
      };
      "cpu" = {
        interval = 1;
        format = " {usage:2}%";
        tooltip = true;
      };
      "disk" = {
        format = " {free}";
        tooltip = true;
      };
      "tray" = {
        spacing = 12;
      };
      "custom/startmenu" = {
        tooltip = false;
        format = "";
        # exec = "rofi -show drun";
        on-click = "sleep 0.1 && rofi-launcher";
      };
      "custom/hyprbindings" = {
        tooltip = false;
        format = "󱕴";
        on-click = "sleep 0.1 && list-hypr-bindings";
      };
      "custom/music" = {
        format = "󰎇 {} 󰎇";
        interval = 1;
        on-click = "playerctl -p Feishin play-pause";
        exec = lib.trivial.readFile ./scripts/music.sh;
      };
      "custom/nvidia" = {
        format = " {}";
        interval = 1;
        exec = lib.meta.getExe nvidiaStatus;
      };
      # There might already be a custom module for this but I'm just going to use my old script.
      "custom/weather" = {
        interval = 900;
        exec = lib.trivial.readFile ./scripts/weather.sh;
      };
    }
  ];
  programs.waybar.style = lib.trivial.readFile ./waybar.css;
}
