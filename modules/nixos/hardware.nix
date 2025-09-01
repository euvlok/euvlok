{
  inputs,
  pkgs,
  lib,
  config,
  pkgsUnstable,
  ...
}:
{
  options.nixos.nvidia.enable = lib.mkEnableOption "Enable NVIDIA drivers & Env Variables";
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
    #! no longer needed for nvidia gpus
    # (lib.mkIf (config.nixos.nvidia.enable && config.nixpkgs.hostPlatform.isx86_64) {
    #   hardware.graphics.extraPackages32 = builtins.attrValues {
    #     inherit (pkgs.driversi686Linux) libva-vdpau-driver libvdpau-va-gl;
    #   };
    # })
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
        GSK_RENDERER = "ngl"; # temp solution until nvidia fixes wayland vulkan backend for gtk apps
      };

      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "580.76.05";
          sha256_64bit = "sha256-IZvmNrYJMbAhsujB4O/4hzY8cx+KlAyqh7zAVNBdl/0=";
          sha256_aarch64 = lib.fakeSha256;
          openSha256 = "sha256-xEPJ9nskN1kISnSbfBigVaO6Mw03wyHebqQOQmUg/eQ=";
          settingsSha256 = "sha256-ll7HD7dVPHKUyp5+zvLeNqAb6hCpxfwuSyi+SAXapoQ=";
          persistencedSha256 = lib.fakeSha256;
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
            "google-chrome"
            "microsoft-edge"
            "vivaldi"
          ];
        in
        (map (browser: _: prev: {
          ${browser} = prev.${browser}.override { inherit commandLineArgs; };
        }) browsers)
        ++ [ inputs.nvidia-patch-trivial.overlays.default ];
    })
    ((lib.mkIf (config.nixos.amd.enable && config.nixpkgs.hostPlatform.isx86_64)) {
      hardware.graphics.extraPackages32 = builtins.attrValues {
        inherit (pkgs.driversi686Linux) amdvlk;
      };
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
          [
            "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
          ];
      };
    })
  ];
}
