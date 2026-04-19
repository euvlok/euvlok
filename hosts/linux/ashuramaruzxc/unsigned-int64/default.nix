{ inputs, ... }:
{
  unsigned-int64 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.self.nixosModules.default
      ./configuration.nix
      ./home.nix
      { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml; }
      {
        catppuccin = {
          enable = true;
          accent = "rosewater";
          flavor = "mocha";
        };
      }
      {
        nixos = {
          gnome.enable = true;
          amd.enable = true;
        };
      }
    ];
  };
}
