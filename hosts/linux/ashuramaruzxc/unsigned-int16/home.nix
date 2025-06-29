{
  inputs,
  config,
  lib,
  euvlok,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);

  commonUsers = [
    { home.stateVersion = "25.11"; }
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/starship.nix
    ../../../hm/ashuramaruzxc/vscode.nix
    ../shared/aliases.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
    inputs.sops-nix-trivial.homeManagerModules.sops
    # {
    #   sops = {
    #     age.keyFile = "$HOME/.config/sops/age/keys.txt";
    #     defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
    #   };
    # }
    ../../../../modules/hm
    {
      hm = {
        fastfetch.enable = true;
        helix.enable = true;
        nushell.enable = true;
        nvf.enable = true;
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
      imports =
        [ { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; } ]
        ++ extraImports
        ++ commonUsers;
    };

  userConfigs = {
    root = [ ];
    ashuramaru = [ ];
  };
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs release euvlok; };
    users = lib.mapAttrs (_: extraImports: mkUser extraImports) userConfigs;
  };
}
