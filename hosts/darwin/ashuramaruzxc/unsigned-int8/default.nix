{ inputs, eulib, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs eulib; };
    modules = [
      ../../../../modules/darwin
      ../../../hm/ashuramaruzxc/fonts.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      { services.protonmail-bridge.enable = true; }

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
