{ pkgs, ... }:
{
  programs = {
    thunar = {
      enable = true;
      plugins = builtins.attrValues { inherit (pkgs) thunar-archive-plugin thunar-volman; };
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
    };
    steam = {
      enable = true;
    };

    hyprland.enable = true;

    kdeconnect.enable = true;

    fish.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        glibc
        zlib
        openssl
        curl
        expat
        glib
        nss
        nspr
        dbus
        atk
        at-spi2-atk
        at-spi2-core
        cairo
        gtk3
        pango
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        libxkbcommon
        systemd
        alsa-lib
        mesa
        libgbm
        libxcrypt
        bzip2
        xz
        libffi
        sqlite
        ncurses
        readline
      ];
    };

    appimage = {
      enable = true;
      binfmt = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/etc/nixos/";
    };

    wireshark.enable = true;
    partition-manager.enable = true;
    gpu-screen-recorder.enable = true;
    virt-manager.enable = true;
  };
}
