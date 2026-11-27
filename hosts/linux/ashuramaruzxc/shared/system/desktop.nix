{ pkgs, lib, ... }:
{
  imports = [
    ./desktop/plasma.nix
  ];

  environment.systemPackages = lib.attrsets.attrValues {
    inherit (pkgs) bitwarden-desktop keepassxc;
  };

  services.libinput.mouse = {
    accelProfile = "flat";
    accelSpeed = "0";
  };

}
