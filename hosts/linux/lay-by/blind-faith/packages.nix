{ zenBrowserPackage }:
{ lib, pkgs, ... }:
{
  environment.localBinInPath = true;
  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      # Base System
      wget
      git
      libsecret
      ffmpeg
      hyprpolkitagent
      usbutils
      net-tools
      desktop-file-utils
      unzip
      p7zip
      file
      font-manager
      killall
      # Desktop
      wayland-protocols
      wayland-utils
      wl-clipboard
      wlroots
      xdg-utils

      # Development
      meson
      gcc
      glibc
      jq
      cachix
      bc
      ninja
      uv

      # QEMU
      #qemu
      #quickemu
      #virt-manager

      # Security
      wireshark

      # Recording
      gpu-screen-recorder
      gpu-screen-recorder-gtk

      ;
    # Theme stuff
    inherit (pkgs.unstable.kdePackages)
      breeze
      breeze-gtk
      breeze-icons
      ;
    inherit (pkgs) seahorse;
    ghidra = pkgs.ghidra.withExtensions (exts: [ exts.reva ]);
    zen-browser = zenBrowserPackage;
  };
}
