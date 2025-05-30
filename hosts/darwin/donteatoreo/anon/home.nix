{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  release = builtins.fromJSON (config.system.darwinRelease);
in
{
  imports = [ inputs.home-manager-donteatoreo.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs release; };
  };

  home-manager.users.anon = {
    imports =
      let
        config =
          { config, ... }:
          [ { home.stateVersion = "25.05"; } ]
          ++ [
            inputs.sops-nix-trivial.homeManagerModules.sops
            {
              sops = {
                age.keyFile = "/Users/anon/sops/age/keys.txt";
                defaultSopsFile = ../../../../secrets/donteatoreo.yaml;
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
            ../../../hm/donteatoreo/aliases.nix
            ../../../../modules/hm
            {
              hm = {
                bash.enable = true;
                fastfetch.enable = true;
                fzf.enable = true;
                ghostty.altKeyBehavior = true;
                ghostty.enable = true;
                git.enable = true;
                helix.enable = true;
                jujutsu.enable = true;
                nixcord.enable = true;
                nushell.enable = true;
                ssh.enable = true;
                vscode.enable = true;
                yazi.enable = true;
                zed.enable = true;
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
              ];
            in
            lib.flatten (map (n: [ ../../../hm/donteatoreo/${n}.nix ]) hmExtraConfigModules)
          );
      in
      config;
  };
}
