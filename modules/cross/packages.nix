{
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages =
    (builtins.attrValues {
      # --- Media ---
      inherit (pkgs)
        ffmpeg-full
        imagemagick
        mediainfo
        yt-dlp
        ;

      # --- Basic CLI Utilities ---
      inherit (pkgs)
        bat
        bc
        btop # Resource monitor (nicer htop)
        curl
        delta # Superior git diff viewer
        diffutils
        dnsutils # For dig, nslookup, etc.
        file
        findutils
        gawk
        gnused
        gnutar
        grep
        iputils # `ping`, `arping`, etc.
        jq
        less
        lsof # List open files
        lz4 # Fast compression algorithm command-line tools
        moreutil
        ncdu
        nmap
        openssh_hpn
        p7zip # CLI 7-Zip tools
        patch
        procps # `ps`, `top`, `free`, `kill`
        psmisc # `pstree`, `killall`, `fuser`
        rsync
        sysstat # `iostat`, `mpstat`, `sar` for system monitoring
        tldr
        tree
        unrar
        unzip
        util-linux # Collection of essential Linux utilities (like `dmesg`, `fdisk`, `mount`)
        wget
        which
        xz
        zip
        ;

      # --- Rust-based CLI Replacements ---
      inherit (pkgs)
        bottom # (alternative to btop)
        duf # Disk Usage/Free utility (df alternative)
        dust # Disk Usage analyzer (du alternative)
        eza # Modern `ls` replacement
        fd # Fast `find` alternative
        hexyl # Command-line hex viewer
        hyperfine # CLI benchmarking tool
        procs # Modern `ps` replacement
        ripgrep # Fast `grep` alternative (rg)
        sd # `sed` alternative
        tokei # Code statistics (cloc alternative)
        xh # Friendly `curl` alternative for HTTP requests
        ;

      # --- System / Hardware ---
      inherit (pkgs)
        smartmontools # Utilities for disk health monitoring (S.M.A.R.T.)
        pciutils # `lspci`
        ;

      # --- Networking ---
      inherit (pkgs)
        netcat-gnu # GNU netcat (often preferred over OpenBSD version for features)
        ;

      # --- Dev Tools ---
      inherit (pkgs)
        # --- General ---
        clang
        cmake
        gcc
        gnumake
        ;
    })
    # --- Concatenate with Linux-specific packages ---
    ++ lib.optionals config.nixpkgs.hostPlatform.isLinux (
      builtins.attrValues {
        # --- Media ---
        inherit (pkgs) ffmpegthumbs; # Video thumbnail generator for file managers

        # --- Networking ---
        inherit (pkgs)
          bsd-finger # User information lookup protocol client
          mtr # Network diagnostic tool (combines traceroute and ping)
          iftop # Display bandwidth usage on an interface (TUI)
          nethogs # Display per-process network usage (TUI)
          wireguard-tools # WireGuard VPN command-line tools
          ;

        # --- Desktop/Audio ---
        inherit (pkgs)
          pavucontrol # PulseAudio Volume Control GUI
          playerctl # Control media players via MPRIS (CLI)
          networkmanagerapplet # GUI applet for NetworkManager
          ;

        # --- Clipboard Tools ---
        inherit (pkgs)
          wl-clipboard-rs # Wayland clipboard (wl-copy/wl-paste) - Rust version
          xclip # X11 clipboard CLI
          clipcat # Clipboard manager (works across X11/Wayland)
          wayland-protocols
          wayland-utils
          ;

        # --- System / Hardware ---
        inherit (pkgs)
          pciutils # `lspci`
          hdparm # Get/set SATA/IDE device parameters
          lm_sensors # Tools for monitoring hardware sensors (needs configuration)
          ;

        # --- Theme stuff ---
        inherit (pkgs.kdePackages)
          breeze
          breeze-gtk
          breeze-icons
          ;
      }
    );
}
