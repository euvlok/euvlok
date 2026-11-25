{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  nvidiaDriver =
    (config.boot.kernelPackages.nvidiaPackages.mkDriver pkgs.nvidia-driver.mkDriverArgs).overrideAttrs
      (previous: {
        passthru = previous.passthru // {
          # nixpkgs only fetches open modules from GitHub, which can lag releases
          open = previous.passthru.open.overrideAttrs {
            src = pkgs.nvidia-driver.open.src;
          };
        };
      });
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
        #! heavy flickering
        # __GL_VRR_ALLOWED = "0";
        # __GLX_VRR_ALLOWED = "0";

        #! kwin 6.8-6.8.1 regression
        #! causes screen freeze when gpu is under ANY! load
        #! this will cause slight performance degradation but at least doesnt freezes display :/usi
        KWIN_DRM_DISABLE_TRIPLE_BUFFERING = lib.modules.mkIf config.euvlok.nixos.plasma.enable "1";
      };

      hardware.nvidia = {
        open = true;
        package =
          if pkgs.stdenv.hostPlatform.isx86_64 then
            pkgs.nvidia-patch.patch-fbc nvidiaDriver
          else
            nvidiaDriver;
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

      nixpkgs.overlays = [
        euvlokInputs.nvidia-patch.overlays.default
        (_: prev: {
          nvidia-patch-list = prev.nvidia-patch-list // {
            fbc = {
              # The 620.70.06 patch also matches the pinned 620.73.04 driver
              "620.73.04" =
                ''s/\x85\xc0\x0f\x85\x1c\x01\x00\x00\x48\x8d/\x85\xc0\x90\x90\x90\x90\x90\x90\x48\x8d/g'';
            }
            // prev.nvidia-patch-list.fbc;
          };
        })
      ];
    })
  ];
}
