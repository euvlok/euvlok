{ inputs, eulib, ... }:
{
  anons-Mac-mini = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ../../../../modules/darwin
      ./configuration.nix
      ./fonts.nix
      ./home.nix
      ./system.nix

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
