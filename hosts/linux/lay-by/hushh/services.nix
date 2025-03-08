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

    xserver.videoDrivers = [ "nvidia" ];

    # Keep AMD microcode up to date
    ucodenix = {
      enable = true;
      cpuModelId = "00800F11";
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
