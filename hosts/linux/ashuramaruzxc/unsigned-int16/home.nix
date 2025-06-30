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
    ../../../hm/ashuramaruzxc/aliases.nix
    ../../../hm/ashuramaruzxc/dconf.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/ssh.nix
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
        bash.enable = true;
        direnv.enable = true;
        fastfetch.enable = true;
        fzf.enable = true;
        ghossty.enable = true;
        helix.enable = true;
        nushell.enable = true;
        # nvf.enable = true;
        # vscode.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zsh.enable = true;
      };
    }
  ];

  mkUser =
    extraImports:
    { inputs, osConfig, ... }:
    {
      imports =
        [ { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; } ]
        ++ extraImports
        ++ commonUsers;
    };

  userConfigs = {
    root = [ ];
    ashuramaru = [
      {
        hm = {
          chromium.enable = true;
          fastfetch.enable = true;
          firefox = {
            enable = true;
            floorp.enable = true;
            zen-browser.enable = true;
            defaultSearchEngine = "kagi";
          };
          mpv.enable = true;
        };
      }
    ];
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
