{
  lib,
  fetchurl,
  fetchFromGitHub,
  nix-update,
  stdenvNoCC,
}:
let
  version = "615.71.09";

  src = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
    hash = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
  };

  aarch64 = fetchurl {
    url = "https://download.nvidia.com/XFree86/Linux-aarch64/${version}/NVIDIA-Linux-aarch64-${version}.run";
    hash = "sha256-IbekQhE7cFfmnPZaLY9NDYcF7CoNZ+2Qb7sRd4EOgWM=";
  };

  open = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "open-gpu-kernel-modules";
    rev = version;
    hash = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
  };

  settings = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-settings";
    rev = version;
    hash = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
  };

  persistenced = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "nvidia-persistenced";
    rev = version;
    hash = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
  };

  # nix-update --subpackage needs a derivation whose `src` is declared in this
  # file. Raw fetchurl/fetchFromGitHub FODs report their position in nixpkgs.
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

  # Version discovery still goes through NVIDIA's directory indexes (see
  # nvidia-prefetch). GitHub is only the release oracle nix-update understands
  # for a .run src.
  updateArgs = [
    "--flake"
    "--format"
    "--url"
    "https://github.com/NVIDIA/open-gpu-kernel-modules"
    "--subpackage"
    "aarch64"
    "--subpackage"
    "open"
    "--subpackage"
    "settings"
    "--subpackage"
    "persistenced"
  ];
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
    inherit updateArgs;
    mkDriverArgs = {
      inherit version;
      sha256_64bit = src.outputHash;
      sha256_aarch64 = aarch64.outputHash;
      openSha256 = open.outputHash;
      settingsSha256 = settings.outputHash;
      persistencedSha256 = persistenced.outputHash;
    };
    updateScript = nix-update.passthru.nix-update-script {
      extraArgs = updateArgs;
      attrPath = "nvidia-driver";
    };
  };

  meta = {
    description = "Pinned NVIDIA Unix driver sources for euvlok hosts";
    homepage = "https://www.nvidia.com/en-us/drivers/unix/";
    platforms = lib.platforms.unix;
  };
}
