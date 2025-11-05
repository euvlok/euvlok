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
          "NVreg_UsePageAttributeTable=1"
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
        __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # without this NOUVEAU may attempt to be used instead
        GBM_BACKEND = "nvidia-drm"; # Required to run the correct GBM backend for NVIDIA GPUs on Wayland
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        #! since it's no longer possible to have latest version not on nixpkgs-unstable
        #! i decided to make it out-of-tree
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "580.105.08";
          sha256_64bit = "sha256-2cboGIZy8+t03QTPpp3VhHn6HQFiyMKMjRdiV2MpNHU=";
          sha256_aarch64 = "sha256-zLRCbpiik2fGDa+d80wqV3ZV1U1b4lRjzNQJsLLlICk="; # Needs to be changed, this was updated before aarch64 version was released
          openSha256 = "sha256-FGmMt3ShQrw4q6wsk8DSvm96ie5yELoDFYinSlGZcwQ=";
          settingsSha256 = "sha256-YvzWO1U3am4Nt5cQ+b5IJ23yeWx5ud1HCu1U0KoojLY=";
          persistencedSha256 = "sha256-qh8pKGxUjEimCgwH7q91IV7wdPyV5v5dc5/K/IcbruI=";
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
      hardware.graphics.extraPackages32 = builtins.attrValues { inherit (pkgs.driversi686Linux) ; };
    })
    (lib.mkIf config.nixos.amd.enable {
      hardware.graphics.extraPackages = builtins.attrValues {
        inherit (pkgs) clinfo;
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
