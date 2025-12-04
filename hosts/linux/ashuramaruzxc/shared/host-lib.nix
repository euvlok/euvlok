{ inputs }:
let
  mkSopsModule = sopsFile: [
    inputs.sops-nix-trivial.nixosModules.sops
    {
      sops = {
        age.keyFile = "/var/lib/sops/age/keys.txt";
        defaultSopsFile = sopsFile;
      };
    }
  ];

  mkCatppuccinModule =
    {
      accent,
      flavor ? "mocha",
      extra ? { },
    }:
    [
      inputs.catppuccin-trivial.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          inherit accent flavor;
        }
        // extra;
      }
    ];
in
{
  mkHostSystem =
    {
      systemLib ? inputs.nixpkgs-ashuramaruzxc.lib,
      modules,
      sopsFile,
      catppuccinAccent,
      catppuccinFlavor ? "mocha",
      catppuccinExtra ? { },
      extraModules ? [ ],
      specialArgs ? { inherit inputs; },
    }:
    systemLib.nixosSystem {
      inherit specialArgs;
      modules =
        modules
        ++ mkSopsModule sopsFile
        ++ mkCatppuccinModule {
          accent = catppuccinAccent;
          flavor = catppuccinFlavor;
          extra = catppuccinExtra;
        }
        ++ extraModules;
    };
}
