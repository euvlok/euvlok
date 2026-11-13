{ pkgs, lib, ... }:
{
  imports = [
    ./desktop/gnome.nix
    ./desktop/plasma.nix
  ];

  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      bitwarden-desktop
      keepassxc
      ;
  };

  services.libinput.mouse = {
    accelProfile = "flat";
    accelSpeed = "0";
  };

}
