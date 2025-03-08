_: {
  services = {
    xserver.enable = true;
    libinput.enable = true;
    gnome.gnome-keyring.enable = true;
    pipewire.enable = true;
    pipewire = {
      alsa.enable = true;
      alsa.support32Bit = true;
      audio.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      wireplumber.extraConfig = {
        # Fixes the "Corsair HS80 Wireless" Volume desync between Headset & System
        "volume-sync" = {
          "bluez5.enable-absolute-volume" = true;
        };
      };
    };
  };
}
