{
  inputs,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  release =
    if builtins.hasAttr "darwinRelease" config.system then
      builtins.fromJSON (config.system.darwinRelease)
    else
      builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-donteatoreo.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.anon =
      { config, ... }:
      {
        imports = [
          { home.stateVersion = "24.11"; }
          inputs.catppuccin.homeModules.catppuccin
          { inherit (osConfig) catppuccin; }

          ../../../hm/donteatoreo/ghostty.nix
          ../../../hm/donteatoreo/git.nix
          ../../../hm/donteatoreo/helix.nix
          ../../../hm/donteatoreo/nixcord.nix
          ../../../hm/donteatoreo/nushell.nix
          ../../../hm/donteatoreo/ssh.nix
          ../../../hm/donteatoreo/starship.nix
          ../../../hm/donteatoreo/yazi.nix

          inputs.sops-nix.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/donteatoreo.yaml;
              secrets.github_ssh = { };
            };
          }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              fastfetch.enable = true;
              fzf.enable = true;
              ghostty.altKeyBehavior = true;
              ghostty.enable = true;
              helix.enable = true;
              jujutsu.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zellij.enable = true;
            };
          }

          # Misc
          {
            home = {
              file.".warp/themes".source =
                (pkgs.callPackage ../../../../pkgs/warp-terminal-catppuccin.nix {
                  inherit (config.catppuccin) accent;
                }).outPath
                + "/share/warp/themes";
              file."Documents/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
                  inherit (config.catppuccin) accent flavor;
                }).outPath
                + "/dist/import.json";
              shellAliases = import ../../../hm/donteatoreo/aliases.nix { };
            };
          }
        ];
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
