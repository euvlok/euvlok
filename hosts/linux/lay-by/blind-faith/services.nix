{ lib, ... }:
{
  # Make HDMI available again when the graphical login starts.
  systemd.services.display-manager.preStart = lib.modules.mkBefore ''
    for connector in /sys/class/drm/card*-HDMI-A-1/status; do
      if [ -e "$connector" ]; then
        if ! printf 'detect\n' > "$connector"; then
          printf 'Failed to restore HDMI detection for %s\n' "$connector" >&2
        fi
      fi
    done
  '';

  # Back gaming.slice's protection through the system-level cgroup ancestors.
  # These are shared budgets, not reservations or protection for every child.
  systemd.slices."user".sliceConfig.MemoryLow = "8G";
  systemd.slices."user-1000".sliceConfig.MemoryLow = "8G";
  systemd.services."user@1000" = {
    # Preserve user@.service's ExecStart and session setup for this instance.
    overrideStrategy = "asDropin";
    serviceConfig.MemoryLow = "8G";
  };

  systemd.services.navidrome.serviceConfig = {
    BindReadOnlyPaths = [ "/media/HDD/spotmusic/" ];
  };
  services = {
    scx-loader = {
      enable = true;
      config = {
        default_sched = "scx_lavd";
        default_mode = "Auto";
      };
    };

    # Target the game SSD by stable identity, even if its sdX name changes.
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_SERIAL}=="WDC_WDS100T2B0B-00YS70_190735484104", TEST=="queue/scheduler", ATTR{queue/scheduler}="kyber"
    '';

    tailscale = {
      enable = false;
      extraSetFlags = [ "--ssh" ];
    };

    xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable systemd-resolved to properly manage dynamic interfaces like tailscale0
    resolved = {
      enable = true;
      settings.Resolve = {
        DNSSEC = "true";
        Domains = [ "~." ];
      };
    };

    displayManager = {
      autoLogin = {
        enable = true;
        user = "hushh";
      };
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    syncthing = {
      enable = false;
      settings.folders = {
        "Music" = {
          path = "/media/HDD/spotmusic/";
        };
      };
    };

    navidrome = {
      enable = false;
      settings = {
        MusicFolder = "/media/HDD/spotmusic/";
        Port = 4533;
        Address = "127.0.0.1";
        EnableSharing = false;
        CoverJpegQuality = 95;
        ScanSchedule = "@every 1h"; # Or "@every 24h"
      };
    };

    libinput = {
      enable = true;
      mouse.accelProfile = "flat";
      mouse.accelSpeed = "0";
    };

    # Misc services
    earlyoom = {
      enable = false;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };

    gvfs.enable = true;
    tumbler.enable = true;
    dbus.enable = true;

    # Necessary for piper
    ratbagd.enable = true;
  };
}
