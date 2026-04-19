_: {

  systemd.services.navidrome.serviceConfig = {
    BindReadOnlyPaths = [ "/media/HDD/spotmusic/" ];
  };
  services = {
    xserver.xkb = {
      layout = "us";
      variant = "";
    };

    libinput.mouse.accelProfile = "flat";

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

    ollama = {
      enable = true;
      acceleration = "cuda";
    };

    syncthing = {
      enable = true;
      settings.folders = {
        "Music" = {
          path = "/media/HDD/spotmusic/";
        };
      };
    };

    navidrome = {
      enable = true;
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
    gvfs.enable = true;
    tumbler.enable = true;
    dbus.enable = true;

    # Necessary for piper
    ratbagd.enable = true;
    blueman.enable = true;
  };
}
