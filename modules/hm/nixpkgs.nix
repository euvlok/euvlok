{
  lib,
  osConfig ? null,
  ...
}:
{
  imports = [ ../cross/nixpkgs.nix ];

  config = lib.mkIf (osConfig != null && osConfig ? nixos) {
    nixpkgs.config.cudaSupport = lib.mkDefault (osConfig.nixos.nvidia.enable or false);
    nixpkgs.config.rocmSupport = lib.mkDefault (osConfig.nixos.amd.enable or false);
  };
}
