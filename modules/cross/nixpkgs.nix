{
  inputs,
  config,
  lib,
  ...
}:
{
  options.cross.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs";
    allowUnfree = lib.mkEnableOption "Unfree Packages";
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.cross.nixpkgs.enable {
    nixpkgs = {
      config = { inherit (config.cross.nixpkgs) allowUnfree cudaSupport; };
      overlays = [ inputs.nur.overlays.default ];
    };
  };
}
