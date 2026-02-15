_: {
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
          path = "/media/HDD/music";
        };
      };
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
