_: {

  systemd.services.navidrome.serviceConfig = {
    BindReadOnlyPaths = [ "/media/HDD/spotmusic/" ];
  };
  services = {
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
    blueman.enable = true;
  };
}
