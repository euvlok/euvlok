{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../shared/system/android.nix
    ../shared/system/containers.nix
    ../shared/system/firmware.nix
    ../shared/system/fonts.nix
    ../shared/system/hyperv.nix
    ../shared/system/lxc.nix
    ../shared/system/nix-credentials.nix
    ../shared/system/settings.nix
    ./hardware-configuration.nix
    ./services/default.nix
    ./settings.nix
    ./users.nix
    ./wireguard.nix
  ];

  security = {
    # Administer the cache with sudo ccache --dir=/var/cache/ccache.
    wrappers.nix-ccache.enable = false;
    sudo = {
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
  };

  programs = {
    ccache.enable = true;
    gnupg.dirmngr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };
  virtualisation.kvmfr.enable = lib.modules.mkForce false;

  virtualisation.oci-containers.containers.byparr = {
    image = "ghcr.io/thephaseless/byparr:latest";
    autoStart = true;
    environment = {
      HOST = "0.0.0.0";
      PORT = "8191";
    };
    ports = [ "172.16.31.1:8191:8191/tcp" ];
    extraOptions = [
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges"
    ];
  };
  nix.settings.extra-sandbox-paths = [ config.programs.ccache.cacheDir ];

  nixpkgs.overlays = [
    (
      final: prev:
      let
        ccache = lib.meta.getExe final.buildPackages.ccache;
        withCcache =
          package:
          package.overrideAttrs (old: {
            # Launchers retain MAGMA's ROCm compiler selection and also reach
            # Torch's CMake invocation through its Python build backend.
            env = (old.env or { }) // {
              CCACHE_DIR = config.programs.ccache.cacheDir;
              CCACHE_UMASK = "007";
              CCACHE_SLOPPINESS = "random_seed";
              CMAKE_C_COMPILER_LAUNCHER = ccache;
              CMAKE_CXX_COMPILER_LAUNCHER = ccache;
              CMAKE_HIP_COMPILER_LAUNCHER = ccache;
            };
          });
      in
      {
        onnxruntime = withCcache prev.onnxruntime;
        magma = withCcache prev.magma;
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_pythonFinal: pythonPrev: {
            torch = withCcache pythonPrev.torch;
          })
        ];
      }
    )
  ];

  environment.systemPackages = [ pkgs.ccache ];
  environment.shells = lib.attrsets.attrValues { inherit (pkgs) zsh bash fish; };

  euvlok.nixos.locale = {
    enable = true;
    timeZone = "Europe/Berlin";
  };

  services.avahi.enable = lib.modules.mkForce false;
  services.displayManager.gdm.autoSuspend = false;

  system.stateVersion = "26.11";
}
