{
  inputs,
  config,
  lib,
  euvlok,
  pkgsUnstable,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);

  commonUsers = [
    { home.stateVersion = "25.05"; }
    ../../../hm/ashuramaruzxc/helix.nix
    ../../../hm/ashuramaruzxc/aliases.nix
    ../../../hm/ashuramaruzxc/starship.nix
    ../../../hm/ashuramaruzxc/vscode.nix
    ../shared/aliases.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
    inputs.sops-nix-trivial.homeManagerModules.sops
    {
      sops = {
        age.keyFile = "$HOME/.config/sops/age/keys.txt";
        defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
      };
    }
    ../../../../modules/hm
    {
      hm = {
        fastfetch.enable = true;
        ghostty.enable = true;
        helix.enable = true;
        nh.enable = true;
        nushell.enable = true;
        vscode.enable = true;
        yazi.enable = true;
        zellij.enable = true;
      };
    }
  ];

  mkUser =
    extraImports:
    { osConfig, ... }:
    {
      imports = [
        { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
      ]
      ++ extraImports
      ++ commonUsers;
    };

  userConfigs = {
    root = [ ];
    ashuramaru = [ ];
    fumono = [ ../../../hm/2husecondary/git.nix ];
    minecraft = [ ];
  };
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {
      inherit
        inputs
        release
        euvlok
        pkgsUnstable
        ;
    };
    users = lib.mapAttrs (_: extraImports: mkUser extraImports) userConfigs;
  };
}
