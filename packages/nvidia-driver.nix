{
  lib,
  fetchurl,
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
let
  # renovate: datasource=github-tags depName=nvidia-driver packageName=NVIDIA/open-gpu-kernel-modules
  version = "615.78.08";

  src = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    hash = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
  };

  aarch64 = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-aarch64/${version}/NVIDIA-Linux-aarch64-${version}.run";
    hash = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
  };

  open = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "open-gpu-kernel-modules";
    rev = version;
    hash = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
  };

  settings = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-settings";
    rev = version;
    hash = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
  };

  persistenced = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-persistenced";
    rev = version;
    hash = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
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
stdenvNoCC.mkDerivation {
  pname = "nvidia-driver";
  inherit version src;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    runHook postInstall
  '';

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
