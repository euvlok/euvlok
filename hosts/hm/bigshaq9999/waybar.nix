_: {
  programs.waybar.enable = true;
  programs.waybar.settings.mainBar = {
    layer = "top";
    position = "top";
    height = 20;
    modules-left = [ "niri/workspaces" ];
    modules-center = [ "niri/window" ];
    modules-right = [
      "idle_inhibitor"
      "pulseaudio"
      "network"
      "bluetooth"
      "power-profiles-daemon"
      "cpu"
      "memory"
      "temperature"
      "backlight"
      "keyboard-state"
      "battery"
      "clock"
      "tray"
    ];
    keyboard-state = {
      numlock = true;
      capslock = true;
      format = "{name} {icon}";
      format-icons = {
        locked = "";
        unlocked = "";
      };
    };
    tray = {
      spacing = 10;
    };
    clock = {
      format = "{:%Y-%m-%d %H:%M}";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    };
    cpu = {
      format = "{usage}% ";
      tooltip = false;
    };
    memory = {
      format = "{}% ";
    };
    temperature = {
      format = "{temperatureC}°C";
    };
    backlight = {
      format = "{percent}% {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
      ];
    };
    battery = {
      states = {
        good = 95;
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-full = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
    };
    power-profiles-daemon = {
      format = "{icon}";
      tooltip-format = "Power profile: {profile}\nDriver: {driver}";
      tooltip = true;
      format-icons = {
        default = "";
        performance = "";
        balanced = "";
        power-saver = "";
      };
    };
    network = {
      format-wifi = "{bandwidthTotalBits} ({signalStrength}%) ";
      format-ethernet = "{ipaddr}/{cidr}";
      tooltip-format = "{ifname} via {gwaddr}";
      format-linked = "{ifname} (No IP)";
      format-disconnected = "Disconnected ⚠";
      format-alt = "{essid}: {ipaddr}/{cidr}";
    };
    pulseaudio = {
      scroll-step = 1; # %, can be a float
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [
          ""
          ""
          ""
        ];
      };
      on-click = "pavucontrol";
    };
    bluetooth = {
      format = "  {status} ";
      format-off = "";
      format-connected = " {num_connections} connected";
      tooltip-format = "{controller_alias}\t{controller_address}";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
    };
  };
}
