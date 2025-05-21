{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-ashuramaruzxc.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../../hm/ashuramaruzxc/fonts.nix
      ../../shared/system.nix
      ./brew.nix
      ./configuration.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../shared/protonmail-bridge.nix
      {
        services.protonmail-bridge.enable = true;
      }
      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
