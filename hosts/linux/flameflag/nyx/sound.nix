_: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.extraConfig = {
      # Fixes the "Corsair HS80 Wireless" volume desync between headset and system.
      "volume-sync" = {
        "bluez5.enable-hw-volume" = false;
      };
    };
  };
}
