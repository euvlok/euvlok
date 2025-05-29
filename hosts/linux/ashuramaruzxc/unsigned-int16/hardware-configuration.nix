{ pkgs, lib, ... }:
{
  system.fsPackages = [ pkgs.sshfs ];
  environment.systemPackages = [ pkgs.cifs-utils ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
