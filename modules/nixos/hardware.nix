{
  inputs,
  pkgs,
  lib,
  config,
  pkgsUnstable,
  ...
}:
{
  options.nixos.nvidia.enable = lib.mkEnableOption "NVIDIA drivers & Env Variables";
  options.nixos.amd.enable = lib.mkEnableOption "AMD drivers";

  config = lib.mkMerge [
    (lib.mkIf config.nixpkgs.hostPlatform.isx86_64 {
      hardware.graphics.enable32Bit = true;
    })
    (lib.mkIf config.nixpkgs.hostPlatform.isx86_64 {
      hardware.graphics.extraPackages32 = builtins.attrValues {
        inherit (pkgs) libva libva-vdpau-driver libvdpau-va-gl;
      };
    })
    ({
      environment.systemPackages = builtins.attrValues { inherit (pkgs) libva-utils; };

      hardware = {
        graphics = {
          enable = true;
          extraPackages = builtins.attrValues {
            inherit (pkgs)
              libva
              mesa
              vulkan-loader
              ;
          };
        };

        bluetooth.enable = true;
        bluetooth.powerOnBoot = false;
      };
    })
    (lib.mkIf config.nixos.nvidia.enable {
      nixpkgs.config.cudaSupport = true;

      services.xserver.videoDrivers = [ "nvidia" ];

      boot.extraModprobeConfig =
        "options nvidia "
        + lib.concatStringsSep " " [
          # NVIDIA assumes that by default your CPU doesn't support `PAT`, but this
          # is effectively never the case in 2023
          "NVreg_UsePageAttributeTable=1"
          # This is sometimes needed for ddc/ci support, see
          # https://www.ddcutil.com/nvidia/
          #
          # Current monitor does not support it, but this is useful for
          # the future
          "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];

      # Credit: https://github.com/NixOS/nixpkgs/issues/202454#issuecomment-1579609974
      environment.etc."egl/egl_external_platform.d".source =
        let
          nvidia_wayland = pkgs.writeText "10_nvidia_wayland.json" ''
            {
                "file_format_version" : "1.0.0",
                "ICD" : {
                    "library_path" : "${pkgsUnstable.egl-wayland}/lib/libnvidia-egl-wayland.so"
                }
            }
          '';
          nvidia_gbm = pkgs.writeText "15_nvidia_gbm.json" ''
            {
                "file_format_version" : "1.0.0",
                "ICD" : {
                    "library_path" : "${config.hardware.nvidia.package}/lib/libnvidia-egl-gbm.so.1"
                }
            }
          '';
        in
        lib.mkForce (
          pkgs.runCommandLocal "nvidia-egl-hack" { } ''
            mkdir -p "$out"
            cp ${nvidia_wayland} "$out/10_nvidia_wayland.json"
            cp ${nvidia_gbm} "$out/15_nvidia_gbm.json"
          ''
        );

      environment.sessionVariables = {
        # Required to run the correct GBM backend for NVIDIA GPUs on Wayland
        GBM_BACKEND = "nvidia-drm";
        # Apparently, without this NOUVEAU may attempt to be used instead
        # (despite it being blacklisted)
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";

        NVD_BACKEND = "direct";
        LIBVA_DRIVER_NAME = "nvidia";
      };

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        #! since it's no longer possible to have latest version not on nixpkgs-unstable
        #! i decided to make it out-of-tree
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "580.95.05";
          sha256_64bit = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
          sha256_aarch64 = "sha256-zLRCbpiik2fGDa+d80wqV3ZV1U1b4lRjzNQJsLLlICk=";
          openSha256 = "sha256-RFwDGQOi9jVngVONCOB5m/IYKZIeGEle7h0+0yGnBEI=";
          settingsSha256 = "sha256-F2wmUEaRrpR1Vz0TQSwVK4Fv13f3J9NJLtBe4UP2f14=";
          persistencedSha256 = "sha256-QCwxXQfG/Pa7jSTBB0xD3lsIofcerAWWAHKvWjWGQtg=";
        };
        powerManagement.enable = true;
        powerManagement.finegrained = false;
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
          commandLineArgs = lib.concatStringsSep " " config.programs.chromium.commandLineArgs;
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
    ((lib.mkIf (config.nixos.amd.enable && config.nixpkgs.hostPlatform.isx86_64)) {
      hardware.graphics.extraPackages32 = builtins.attrValues { inherit (pkgs.driversi686Linux) amdvlk; };
    })
    (lib.mkIf config.nixos.amd.enable {
      hardware.graphics.extraPackages = builtins.attrValues {
        inherit (pkgs) amdvlk clinfo;
        inherit (pkgs.rocmPackages.clr) icd;
      };
      environment.systemPackages = builtins.attrValues { inherit (pkgs) lact; };
      systemd = {
        packages = builtins.attrValues { inherit (pkgs) lact; };
        services.lactd.wantedBy = [ "multi-user.target" ];
        tmpfiles.rules =
          let
            rocmEnv = pkgs.symlinkJoin {
              name = "rocm-combined";
              paths = builtins.attrValues {
                inherit (pkgs.rocmPackages)
                  rocblas
                  hipblas
                  clr
                  ;
              };
            };
          in
          [ "L+    /opt/rocm   -    -    -     -    ${rocmEnv}" ];
      };
    })
  ];
}
