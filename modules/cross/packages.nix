{ isDarwin }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  commonPkgs = lib.attrsets.attrValues {
    # Nix Related
    inherit (pkgs.unstable)
      cachix
      nixfmt
      nil
      nixd
      ;

    uutils-coreutils-noprefix = lib.meta.hiPrio pkgs.unstable.uutils-coreutils-noprefix;
    uutils-diffutils = lib.meta.hiPrio pkgs.unstable.uutils-diffutils;
    uutils-findutils = lib.meta.hiPrio pkgs.unstable.uutils-findutils;

    # GNU
    inherit (pkgs.unstable)
      gawk
      gnugrep
      gnused
      gnutar
      ;

    # Core Utilities
    inherit (pkgs.unstable)
      bc
      moreutils # Collection of handy Unix tools (parallel, sponge, ts, ...)
      patch
      procps # Utilities for monitoring system processes (ps, top, kill...)
      tldr # Simplified man pages
      tree
      util-linux # Essential Linux utilities (dmesg, fdisk, mount...)
      which
      bchunk
      ;

    # Modern UNIX
    inherit (pkgs.unstable)
      bat # cat
      bottom # htop & btop
      btop # top
      broot # tree
      delta # difff
      duf # df
      dust # du
      eza # ls
      fd # find
      procs # ps
      ripgrep # grep
      sd # sed
      xh # curl
      ;

    # Compression
    inherit (pkgs.unstable)
      unrar
      unzip
      zip
      zstd
      ;
    inherit (pkgs.unstable)
      lz4
      ncdu
      p7zip
      pandoc
      rsync
      xz
      ;

    inherit (pkgs.unstable)
      hexyl # CLI hex viewer
      jq # CLI JSON processor
      less
      ;

    # Networking
    inherit (pkgs.unstable)
      curl
      dnsutils # `dig`, `nslookup`, etc.
      openssh_hpn # SSH client/server (High Performance Networking patches)
      wget
      ;

    inherit (pkgs.unstable)
      imagemagick
      mediainfo
      ;
    inherit (pkgs.stable) ffmpeg-full;

    # Media
    inherit (pkgs.eupkgs)
      yt-dlp
      yt-dlp-script
      ;

    # Development Tools (enable `euvlok.home.languages.*`) for stuff like cmake, gnumake, cargo, etc.)
    inherit (pkgs.unstable) hyperfine tokei;

  };
  graphicalLinux =
    !isDarwin && config.nixpkgs.hostPlatform.isLinux && (config.euvlok.nixos.gui.enable or false);
  linuxOnlyPkgs =
    lib.attrsets.attrValues {
      # Networking
      inherit (pkgs.unstable)
        iftop # TUI display of bandwidth usage on an interface
        iputils
        mtr # Network diagnostic tool (traceroute + ping)
        nethogs # TUI display of per-process network usage
        wireguard-tools
        ;

      # System / Hardware
      inherit (pkgs.unstable)
        hdparm
        lm_sensors # Tools for monitoring hardware sensors
        psmisc
        ;

      inherit (pkgs.unstable)
        xclip # X11 clipboard CLI utility
        wl-clipboard-rs # Wayland clipboard utilities (wl-copy/wl-paste)
        clipcat # Clipboard manager (X11/Wayland)
        ;

      # Misc
      inherit (pkgs.unstable) sysstat;
    }
    # Pacakges only meant for Desktops
    ++ lib.lists.optionals graphicalLinux (
      lib.attrsets.attrValues {
        inherit (pkgs.unstable)
          networkmanagerapplet
          pavucontrol # PulseAudio Volume Control GUI
          playerctl # Control media players via MPRIS (CLI)
          ;

        inherit (pkgs.unstable.kdePackages) ffmpegthumbs;
        inherit (pkgs.unstable.kdePackages) breeze breeze-gtk breeze-icons;
      }
    );
in
{
  options.euvlok.packages.enable =
    lib.options.mkEnableOption "euvlok's shared system package profile"
    // {
      default = true;
    };

  config = lib.modules.mkIf config.euvlok.packages.enable (
    if isDarwin then
      {
        environment.system.packages = commonPkgs;
      }
    else
      {
        environment.systemPackages =
          commonPkgs ++ lib.lists.optionals config.nixpkgs.hostPlatform.isLinux linuxOnlyPkgs;
      }
  );
}
