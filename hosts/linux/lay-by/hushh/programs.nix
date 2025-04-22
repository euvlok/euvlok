{ pkgs, inputs, ... }:
{
  programs = {
    thunar = {
      enable = true;
      plugins = builtins.attrValues { inherit (pkgs.xfce) thunar-archive-plugin thunar-volman; };
    };
    gamescope = {
      enable = true;
      # capSysNice = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };
    hyprland = {
      enable = true;
      # set the flake package
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage =
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    kdeconnect.enable = true;

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
