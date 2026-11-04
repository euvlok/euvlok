{
  lib,
  fetchurl,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:
let
  # renovate: datasource=github-tags depName=nvidia-driver packageName=NVIDIA/open-gpu-kernel-modules
  version = "620.70.06";

  src = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    hash = "sha256-KRGOOr0IwHVZvMo9nHYjjQOUkK8DYqLlvPy+cgSv1LE=";
  };

  aarch64 = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-aarch64/${version}/NVIDIA-Linux-aarch64-${version}.run";
    hash = "sha256-P6ZaknHg3eKk5YxJZcOIhaAqOkKszcsm/IF0EGB/PgM=";
  };

  # NVIDIA publishes release archives before the matching GitHub tags
  open = fetchzip {
    url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${version}.tar.xz";
    hash = "sha256-hQ8JyuzBlEu7LIxGDe09+HMWroafUWQYrfxSX127kcQ=";
  };

  settings = fetchzip {
    url = "https://download.nvidia.com/XFree86/nvidia-settings/nvidia-settings-${version}.tar.bz2";
    hash = "sha256-CFBRmXFJ9eAf5BRlHMBolahz1Pshr9giI7zcZC29oZ8=";
  };

  persistenced = fetchzip {
    url = "https://download.nvidia.com/XFree86/nvidia-persistenced/nvidia-persistenced-${version}.tar.bz2";
    hash = "sha256-FpGzhArrvR1nEt8lKDzNEnbvHvGP36gL1dINvpDAkpA=";
  };

  # nix-update --subpackage needs a derivation whose `src` is declared in this
  # file because raw fetchers report their position in nixpkgs
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
  {
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
        sha256_64bit = src.outputHash;
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
