{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  nvidiaDriverConfig = import ./nvidia-driver.nix;
  nvidiaDriver = config.boot.kernelPackages.nvidiaPackages.mkDriver nvidiaDriverConfig;
in
{
  options.nixos.nvidia.enable = lib.options.mkEnableOption "NVIDIA Drivers & Env Variables";

  config = lib.modules.mkMerge [
    (lib.modules.mkIf config.nixos.nvidia.enable {
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
        extraPackages = builtins.attrValues {
          inherit (pkgs) libva-vdpau-driver libvdpau-va-gl nv-codec-headers-12;
        };
      };

      environment.systemPackages = builtins.attrValues {
        inherit (pkgs) zenith-nvidia;
        inherit (pkgs.nvtopPackages) full;
      };

      nixpkgs.overlays =
        let
          commandLineArgs = lib.strings.concatStringsSep " " config.programs.chromium.commandLineArgs;
          browsers = [
            "brave"
            "chromium"
            "google-chrome"
            "microsoft-edge"
            "ungoogled-chromium"
            "vivaldi"
          ];
        in
        (map (browser: _: prev: {
          ${browser} = prev.${browser}.override { inherit commandLineArgs; };
        }) browsers)
        ++ [ inputs.nvidia-patch-trivial.overlays.default ];
    })
  ];
}
