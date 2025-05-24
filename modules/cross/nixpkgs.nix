{
  inputs,
  config,
  lib,
  ...
}:
{
  options.cross.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs";
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.cross.nixpkgs.enable {
    nixpkgs = {
      config = {
        allowUnfree = true;
        inherit (config.cross.nixpkgs) cudaSupport;
      };
      overlays = [
        inputs.nur-trivial.overlays.default
      ] ++ [ (final: prev: { yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { }; }) ];
    };
  };
}
