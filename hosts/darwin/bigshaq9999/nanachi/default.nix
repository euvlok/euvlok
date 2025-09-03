{ inputs, eulib, ... }:
{
  faputa = inputs.nix-darwin-bigshaq9999.lib.darwinSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ../../../../modules/darwin
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./fonts.nix

      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
      (
        { config, ... }:
        {
          _module.args.pkgsUnstable = import inputs.nixpkgs-unstable {
            system = "aarch64-darwin";
            config = config.nixpkgs.config;
          };
        }
      )
    ];
  };
}
