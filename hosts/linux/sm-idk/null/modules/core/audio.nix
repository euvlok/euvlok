_: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    audio.enable = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Audio-related security settings
  security.rtkit.enable = true;
  security.polkit.enable = true;

  services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem
}
