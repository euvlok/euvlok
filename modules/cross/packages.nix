{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  commonPkgs = (
    builtins.attrValues {
      # Nix Related
      inherit (inputs.nil.packages.${config.nixpkgs.hostPlatform.system}) nil;
      inherit (pkgs) nixfmt-rfc-style;

      # Core Utilities (Shell essentials, replacements, process management)
      inherit (pkgs)
        bc
        coreutils # Basic file, shell and text manipulation utilities
        diffutils
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        moreutils # Collection of handy Unix tools (parallel, sponge, ts, ...)
        patch
        procps # Utilities for monitoring system processes (ps, top, kill...)
        tldr # Simplified man pages
        util-linux # Essential Linux utilities (dmesg, fdisk, mount...)
        which
        ;

      # Modern Rust/Go/Zig Replacements
      inherit (pkgs)
        bat # cat
        bottom # htop & btop
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

      # File Management & Archiving
      inherit (pkgs)
        rar
        unrar
        unzip
        zip
        ;
      inherit (pkgs)
        lz4
        ncdu
        p7zip
        pandoc
        rsync
        tree
        xz
        ;

      # Text Processing & Viewing
      inherit (pkgs)
        hexyl # CLI hex viewer
        jq # CLI JSON processor
        less
        ;

      # Networking
      inherit (pkgs)
        curl
        dnsutils # `dig`, `nslookup`, etc.
        netcat-gnu # GNU netcat
        nmap
        openssh_hpn # SSH client/server (High Performance Networking patches)
        wget
        ;

      # System Information & Monitoring
      inherit (pkgs)
        file
        lsof # List open files
        pciutils # lspci
        smartmontools # S.M.A.R.T. disk health monitoring tools
        ;

      # Modern System Info/Monitoring Replacements
      inherit (pkgs)
        btop # TUI resource monitor (C++)
        ;

      # Media
      inherit (pkgs)
        ffmpeg-full
        imagemagick
        mediainfo
        yt-dlp
        ;

      # Development Tools
      inherit (pkgs)
        # Build Tools & Compilers
        clang
        cmake
        gcc
        gnumake
        # Dev Utilities
        hyperfine # CLI benchmarking tool
        tokei # Counts lines of code
        ;
    }
  );

  linuxOnlyPkgs = (
    builtins.attrValues {
      # Networking
      inherit (pkgs)
        iftop # TUI display of bandwidth usage on an interface
        iputils
        mtr # Network diagnostic tool (traceroute + ping)
        nethogs # TUI display of per-process network usage
        wireguard-tools
        ;

      # System / Hardware
      inherit (pkgs)
        hdparm
        lm_sensors # Tools for monitoring hardware sensors
        psmisc
        ;

      # Clipboard Tools
      inherit (pkgs)
        xclip # X11 clipboard CLI utility
        wl-clipboard-rs # Wayland clipboard utilities (wl-copy/wl-paste)
        clipcat # Clipboard manager (X11/Wayland)
        ;

      # Misc
      inherit (pkgs) sysstat;
    }
    # Pacakges only meant for Desktops
    // lib.optionalAttrs (config.nixos.amd.enable or config.nixos.nvidia.enable) {
      inherit (pkgs)
        networkmanagerapplet
        pavucontrol # PulseAudio Volume Control GUI
        playerctl # Control media players via MPRIS (CLI)
        ;

      inherit (pkgs.kdePackages) ffmpegthumbs;
      inherit (pkgs) nufraw-thumbnailer;

      inherit (pkgs.kdePackages) breeze breeze-gtk breeze-icons;
    }
  );
in
{
  environment.systemPackages =
    commonPkgs
    ++ lib.optionals config.nixpkgs.hostPlatform.isLinux linuxOnlyPkgs;
}
