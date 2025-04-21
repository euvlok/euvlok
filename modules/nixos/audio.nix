{ lib, config, ... }:
{
  services = {
    pipewire.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    audio.enable = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
// lib.optionalAttrs ((builtins.fromJSON config.system.nixos.release) < 25) {
  hardware.pulseaudio.enable = false;
}
// lib.optionalAttrs ((builtins.fromJSON config.system.nixos.release) > 25) {
  services.pulseaudio.enable = false;
}
