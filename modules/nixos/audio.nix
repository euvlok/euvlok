{ config, lib, ... }:
{
  options.euvlok.nixos.audio.enable =
    lib.options.mkEnableOption "the shared PipeWire audio stack"
    // {
      default = true;
    };

  config = lib.modules.mkIf config.euvlok.nixos.audio.enable {
    environment.systemPackages = [ config.services.pipewire.package.jack ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
