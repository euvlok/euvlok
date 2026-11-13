{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.kmscon = {
    enable = lib.modules.mkDefault true;
    useXkbConfig = lib.modules.mkDefault true;
    config = {
      # Keep software rendering available on hosts without a graphics stack
      hwaccel = lib.modules.mkDefault config.hardware.graphics.enable;
      font-engine = lib.modules.mkDefault "freetype";
      font-name = lib.modules.mkDefault "Hack Nerd Font Mono";
      # Let kmscon choose a readable pixel size for each display
      font-size = lib.modules.mkDefault 0;
      term = lib.modules.mkDefault "kmscon";
      sb-size = lib.modules.mkDefault 10000;
    };
  };

  fonts = lib.modules.mkIf config.services.kmscon.enable {
    fontconfig.enable = true;
    packages = lib.attrsets.attrValues {
      inherit (pkgs) noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji;
      inherit (pkgs.nerd-fonts) hack;
    };
  };
}
