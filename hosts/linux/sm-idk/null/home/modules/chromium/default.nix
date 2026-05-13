{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    extensions = pkgs.callPackage ./extensions.nix { };
  };
}
