{ pkgs, inputs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # Base System
      wget
      git
      libsecret
      ffmpeg
      hyprpolkitagent

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

      # Misc System
      gnome-tweaks
      ssh-askpass-fullscreen
      oterm

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
      kdeconnect-kde
      ;
    inherit (pkgs) seahorse;
    inherit (inputs.zen-browser-trivial.packages.x86_64-linux) default;
  };
}
