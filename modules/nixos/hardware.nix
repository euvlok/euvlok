{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.nixpkgs.hostPlatform.isx86_64 {
      hardware.graphics.enable32Bit = true;
    })
    (lib.modules.mkIf config.nixpkgs.hostPlatform.isx86_64 {
      hardware.graphics.extraPackages32 = lib.attrsets.attrValues {
        inherit (pkgs) libva libva-vdpau-driver libvdpau-va-gl;
      };
    })
    {
      environment.systemPackages = lib.attrsets.attrValues { inherit (pkgs) libva-utils; };
      hardware = {
        graphics = {
          enable = true;
          extraPackages = lib.attrsets.attrValues {
            inherit (pkgs) libva mesa vulkan-loader;
          };
        };
        bluetooth.enable = true;
        bluetooth.powerOnBoot = false;
      };
    }
  ];
}
