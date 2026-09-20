{ config, lib, ... }:
{
  options.euvlok.nixos.audio.enable =
    lib.options.mkEnableOption "the shared PipeWire audio stack"
    // {
      default = true;
    };

  config = lib.modules.mkIf config.euvlok.nixos.audio.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      audio.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
