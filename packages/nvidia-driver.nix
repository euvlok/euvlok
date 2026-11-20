{
  lib,
  fetchurl,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:
let
  # renovate: datasource=github-tags depName=nvidia-driver packageName=NVIDIA/open-gpu-kernel-modules
  version = "620.73.04";

  src = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    hash = "sha256-tfLi1dqENbMlOTBAFbib9+si/grsjNaQW3puip+bjxs=";
  };

  aarch64 = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-aarch64/${version}/NVIDIA-Linux-aarch64-${version}.run";
    hash = "sha256-45QZFS3Hs9hN4tKRrfmripADVpZQqksB7pAEZaS+XkA=";
  };

  # NVIDIA publishes release archives before the matching GitHub tags
  open = fetchzip {
    url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${version}.tar.xz";
    hash = "sha256-iS3Z1O9yHrz/aGL1sysNZ5E/asQM3dliLKqDVlURBBE=";
  };

  settings = fetchzip {
    url = "https://download.nvidia.com/XFree86/nvidia-settings/nvidia-settings-${version}.tar.bz2";
    hash = "sha256-Wrv0F7Eo9X/0Xv5DclI9aIe3FcRtbu9okQJuWBjL8es=";
  };

  persistenced = fetchzip {
    url = "https://download.nvidia.com/XFree86/nvidia-persistenced/nvidia-persistenced-${version}.tar.bz2";
    hash = "sha256-QOndl1q7veD5aB6AfEe0/K2QHR8+ftLsei/aQrUCN3Q=";
  };

  /**
    Expose a pinned NVIDIA source as a derivation without unpacking it

    `nix-update --subpackage` uses the position of the derivation's `src`
    attribute to find these pins. A raw fetcher would point into Nixpkgs

    # Inputs

    `options` (attribute set)

    : `pname` (required)
      : Base name of the source pin

      `src` (required)
      : Fixed-output derivation for the driver installer or source archive

    # Type

    ```
    mkPin :: { pname :: String; src :: Derivation; } -> Derivation
    ```

    # Examples
    :::{.example}
    ## Read the hash of the pinned open kernel modules

    ```nix
    (mkPin { pname = "nvidia-driver-open"; src = open; }).src.outputHash
    => open.outputHash
    ```

    :::
  */
  mkPin =
    {
      pname,
      src,
    }:
    stdenvNoCC.mkDerivation {
      inherit pname version src;
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        runHook postInstall
      '';
    };

in
(mkPin {
  pname = "nvidia-driver";
  inherit src;
}).overrideAttrs
  (
    finalAttrs: _previousAttrs: {
      passthru = {
        aarch64 = mkPin {
          pname = "nvidia-driver-aarch64";
          src = aarch64;
        };
        open = mkPin {
          pname = "nvidia-driver-open";
          src = open;
        };
        settings = mkPin {
          pname = "nvidia-driver-settings";
          src = settings;
        };
        persistenced = mkPin {
          pname = "nvidia-driver-persistenced";
          src = persistenced;
        };
        mkDriverArgs = {
          inherit version;
          sha256_64bit = finalAttrs.src.outputHash;
          sha256_aarch64 = aarch64.outputHash;
          openSha256 = open.outputHash;
          settingsSha256 = settings.outputHash;
          persistencedSha256 = persistenced.outputHash;
        };
        updateScript = nix-update-script {
          attrPath = "nvidia-driver";
          extraArgs = [
            "--flake"
            "--format"
            "--url=https://github.com/NVIDIA/open-gpu-kernel-modules"
            "--subpackage=aarch64"
            "--subpackage=open"
            "--subpackage=settings"
            "--subpackage=persistenced"
          ];
        };
      };

      meta = {
        description = "Pinned NVIDIA Unix driver sources for euvlok hosts";
        homepage = "https://www.nvidia.com/en-us/drivers/unix/";
        platforms = lib.systems.doubles.unix;
      };
    }
  )
