{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  nvidiaDriver = config.boot.kernelPackages.nvidiaPackages.mkDriver pkgs.nvidia-driver.mkDriverArgs;
in
{
  options.euvlok.nixos.nvidia.enable = lib.options.mkEnableOption "NVIDIA Drivers & Env Variables";

  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.euvlok.nixos.nvidia.enable {
      nixpkgs.config.cudaSupport = true;

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.sessionVariables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # without this NOUVEAU may attempt to be used instead
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
        # __GL_VRR_ALLOWED = "0";
        # __GLX_VRR_ALLOWED = "0";
      };

      hardware.nvidia = {
        open = true;
        package = nvidiaDriver;
        videoAcceleration = true;
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        moduleParams = {
          nvidia = {
            NVreg_UsePageAttributeTable = 1;
            NVreg_RegistryDwords = "RMUseSwI2c=0x01;RMI2cSpeed=100";
          };
        };
      };

      hardware.graphics = {
        extraPackages = lib.attrsets.attrValues {
          inherit (pkgs) libva-vdpau-driver libvdpau-va-gl nv-codec-headers-12;
        };
      };

      environment.systemPackages = lib.attrsets.attrValues {
        inherit (pkgs) zenith-nvidia;
        inherit (pkgs.nvtopPackages) full;
      };

      # Home Manager wraps the selected browser with its command-line arguments
      nixpkgs.overlays = [ euvlokInputs.nvidia-patch.overlays.default ];
    })
  ];
}
