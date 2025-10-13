{
  pkgsUnstable,
  lib,
  config,
  ...
}:
let
  commonPkgs = (
    builtins.attrValues {
      # Nix Related
      inherit (pkgsUnstable) nixfmt-rfc-style nil nixd;

      uutils-coreutils-noprefix = (lib.hiPrio pkgsUnstable.uutils-coreutils-noprefix);
      uutils-diffutils = (lib.hiPrio pkgsUnstable.uutils-diffutils);
      uutils-findutils = (lib.hiPrio pkgsUnstable.uutils-findutils);

      # GNU
      inherit (pkgsUnstable)
        gawk
        gnugrep
        gnused
        gnutar
        ;

      # Core Utilities
      inherit (pkgsUnstable)
        bc
        moreutils # Collection of handy Unix tools (parallel, sponge, ts, ...)
        patch
        procps # Utilities for monitoring system processes (ps, top, kill...)
        tldr # Simplified man pages
        tree
        util-linux # Essential Linux utilities (dmesg, fdisk, mount...)
        which
        ;

      # Modern UNIX
      inherit (pkgsUnstable)
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
      inherit (pkgsUnstable) unrar unzip zip;
      inherit (pkgsUnstable)
        lz4
        ncdu
        p7zip
        pandoc
        rsync
        xz
        ;

      inherit (pkgsUnstable)
        hexyl # CLI hex viewer
        jq # CLI JSON processor
        less
        ;

      # Networking
      inherit (pkgsUnstable)
        curl
        dnsutils # `dig`, `nslookup`, etc.
        openssh_hpn # SSH client/server (High Performance Networking patches)
        wget
        ;

      inherit (pkgsUnstable)
        ffmpeg_8-full
        imagemagick
        mediainfo
        yt-dlp
        yt-dlp-script
        ;

      inherit (pkgs) yt-dlp-script;

      # Development Tools (enable `hm.languages.*`) for stuff like cmake, gnumake, cargo, etc.
      inherit (pkgsUnstable) hyperfine tokei;
    }
  );
  linuxOnlyPkgs = (
    builtins.attrValues {
      # Networking
      inherit (pkgsUnstable)
        iftop # TUI display of bandwidth usage on an interface
        iputils
        mtr # Network diagnostic tool (traceroute + ping)
        nethogs # TUI display of per-process network usage
        wireguard-tools
        ;

      # System / Hardware
      inherit (pkgsUnstable)
        hdparm
        lm_sensors # Tools for monitoring hardware sensors
        psmisc
        ;

      inherit (pkgsUnstable)
        xclip # X11 clipboard CLI utility
        wl-clipboard-rs # Wayland clipboard utilities (wl-copy/wl-paste)
        clipcat # Clipboard manager (X11/Wayland)
        ;

      # Misc
      inherit (pkgsUnstable) sysstat;
    }
    # Pacakges only meant for Desktops
    ++ lib.optionals (config.nixos.amd.enable or config.nixos.nvidia.enable) (
      builtins.attrValues {
        inherit (pkgsUnstable)
          networkmanagerapplet
          pavucontrol # PulseAudio Volume Control GUI
          playerctl # Control media players via MPRIS (CLI)
          ;

        inherit (pkgsUnstable.kdePackages) ffmpegthumbs;
        inherit (pkgsUnstable) nufraw-thumbnailer;
        inherit (pkgsUnstable.kdePackages) breeze breeze-gtk breeze-icons;
      }
    )
  );
in
{
  environment.systemPackages =
    commonPkgs ++ lib.optionals config.nixpkgs.hostPlatform.isLinux linuxOnlyPkgs;
}
