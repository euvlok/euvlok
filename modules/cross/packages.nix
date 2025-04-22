{
  pkgs,
  lib,
  config,
  ...
}:
let
  commonPkgs = (
    builtins.attrValues {
      # --- Core Utilities (Shell essentials, replacements, process management) ---
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

      # --- Modern Core Utility Replacements ---
      inherit (pkgs)
        bat # `cat` clone with syntax highlighting and Git integration
        eza # Modern `ls` replacement
        fd # Simple, fast and user-friendly `find` alternative
        procs # Modern `ps` replacement with colored output
        ripgrep # Fast `grep` alternative (rg)
        sd # Intuitive `sed` alternative
        ;

      # --- File Management & Archiving ---
      inherit (pkgs)
        lz4
        ncdu # NCurses Disk Usage analyzer
        p7zip
        rsync
        tree
        unrar
        unzip
        xz
        zip
        ;

      # --- Modern File Management Replacements ---
      inherit (pkgs)
        dust # More intuitive `du` alternative
        ;

      # --- Text Processing & Viewing ---
      inherit (pkgs)
        delta # Feature-rich `diff` viewer, especially for Git
        hexyl # CLI hex viewer
        jq # CLI JSON processor
        less
        ;

      # --- Networking ---
      inherit (pkgs)
        curl
        dnsutils # `dig`, `nslookup`, etc.
        netcat-gnu # GNU netcat
        nmap
        openssh_hpn # SSH client/server (High Performance Networking patches)
        wget
        ;

      # --- Modern Networking Replacements ---
      inherit (pkgs)
        xh # Friendly `curl` alternative for HTTP requests
        ;

      # --- System Information & Monitoring ---
      inherit (pkgs)
        file # Determine file type
        lsof # List open files
        pciutils # `lspci`
        smartmontools # S.M.A.R.T. disk health monitoring tools
        ;

      # --- Modern System Info/Monitoring Replacements ---
      inherit (pkgs)
        bottom # TUI process/system monitor
        btop # TUI resource monitor (C++)
        duf # Disk Usage/Free utility (df alternative)
        ;

      # --- Media ---
      inherit (pkgs)
        ffmpeg-full
        imagemagick
        mediainfo
        yt-dlp
        ;

      # --- Development Tools ---
      inherit (pkgs)
        # --- Build Tools & Compilers ---
        clang
        cmake
        gcc
        gnumake
        # --- Dev Utilities ---
        hyperfine # CLI benchmarking tool
        tokei # Counts lines of code
        ;
    }
  );

  linuxOnlyPkgs = (
    builtins.attrValues {
      # --- Networking ---
      inherit (pkgs)
        bsd-finger
        iftop # TUI display of bandwidth usage on an interface
        iputils
        mtr # Network diagnostic tool (traceroute + ping)
        nethogs # TUI display of per-process network usage
        wireguard-tools
        ;

      # --- System / Hardware ---
      inherit (pkgs)
        hdparm
        lm_sensors # Tools for monitoring hardware sensors
        psmisc
        ;

      # --- Desktop / GUI / Audio ---
      inherit (pkgs)
        networkmanagerapplet
        pavucontrol # PulseAudio Volume Control GUI
        playerctl # Control media players via MPRIS (CLI)
        ;

      # --- Clipboard Tools ---
      inherit (pkgs)
        xclip # X11 clipboard CLI utility
        wl-clipboard-rs # Wayland clipboard utilities (wl-copy/wl-paste)
        clipcat # Clipboard manager (X11/Wayland)
        ;

      # --- Media ---
      inherit (pkgs)
        ffmpegthumbs # Video thumbnail generator for file managers
        ;

      # --- Theming ---
      inherit (pkgs.kdePackages)
        breeze
        breeze-gtk
        breeze-icons
        ;

      # --- Misc ---
      inherit (pkgs)
        sysstat
        ;
    }
  );
in
{
  environment.systemPackages =
    commonPkgs
    ++ lib.optionals config.nixpkgs.hostPlatform.isLinux linuxOnlyPkgs;
}
