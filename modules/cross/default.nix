{ inputs, config, ... }:
{
  imports = [
    ./lib.nix
    ./nix.nix
    ./nixpkgs.nix
    ./packages.nix
  ];

  _module.args.pkgsUnstable = import inputs.nixpkgs-unstable-small {
    inherit (config.nixpkgs.hostPlatform) system;
    inherit (config.nixpkgs) config;
  };
}
