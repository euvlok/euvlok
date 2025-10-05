{
  inputs,
  pkgs,
  lib,
  eulib,
  config,
  pkgsUnstable,
  ...
}:
{
  imports = [ inputs.home-manager-flameflag.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib pkgsUnstable; };
  };

  home-manager.users.${config.system.primaryUser} =
    { config, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
      ]
      ++ [
        inputs.sops-nix-trivial.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "${config.home.homeDirectory}/sops/age/keys.txt";
            defaultSopsFile = ../../../../secrets/flameflag.yaml;
            secrets.github_ssh = { };
          };
        }
      ]
      ++ [
        {
          home.file.".warp/themes".source =
            (pkgs.callPackage ../../../../pkgs/warp-terminal-catppuccin.nix {
              inherit (config.catppuccin) accent;
            }).outPath
            + "/share/warp/themes";
          home.file."Documents/catppuccin-userstyles.json".source =
            (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
              inherit (config.catppuccin) accent flavor;
            }).outPath
            + "/dist/import.json";
        }
      ]
      ++ [
        inputs.catppuccin-trivial.homeModules.catppuccin
        {
          catppuccin = {
            enable = true;
            flavor = "frappe";
            accent = "teal";
          };
        }
      ]
      ++ [
        ../../../hm/flameflag/aliases.nix
        ../../../../modules/hm
        {
          hm = {
            fastfetch.enable = true;
            ghostty.enable = true;
            helix.enable = true;
            jujutsu.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            ssh.enable = true;
            vscode.enable = true;
            yazi.enable = true;
            zed-editor.enable = true;
            zellij.enable = true;
          };
        }
      ]
      ++ (
        let
          hmExtraConfigModules = [
            "ghostty"
            "git"
            "helix"
            "jujutsu"
            "nixcord"
            "nushell"
            "ssh"
            "starship"
            "vscode"
            "yazi"
            "zed"
            "zellij"
          ];
        in
        lib.flatten (map (n: [ ../../../hm/flameflag/${n}.nix ]) hmExtraConfigModules)
      );
    };
}
