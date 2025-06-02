{
  inputs,
  lib,
  config,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-donteatoreo.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs release; };
  };

  home-manager.users.nyx =
    { osConfig, ... }:
    {
      imports =
        let
          config =
            [ { home.stateVersion = "25.05"; } ]
            ++ [
              inputs.sops-nix-trivial.homeManagerModules.sops
              {
                sops = {
                  age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
                  defaultSopsFile = ../../../../secrets/donteatoreo.yaml;
                  secrets.github_ssh = { };
                };
              }
            ]
            ++ [
              inputs.catppuccin-trivial.homeModules.catppuccin
              { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
            ]
            ++ [
              ../../../hm/donteatoreo/aliases.nix
              ../../../../modules/hm
              {
                hm = {
                  bash.enable = true;
                  chromium.browser = "brave";
                  chromium.enable = true;
                  direnv.enable = true;
                  fastfetch.enable = true;
                  firefox.enable = true;
                  firefox.zen-browser.enable = true;
                  fzf.enable = true;
                  ghostty.altKeyBehavior = true;
                  ghostty.enable = true;
                  git.enable = true;
                  helix.enable = true;
                  jujutsu.enable = true;
                  mpv.enable = true;
                  nixcord.enable = true;
                  nushell.enable = true;
                  ssh.enable = true;
                  vscode.enable = true;
                  yazi.enable = true;
                  zed-editor.enable = true;
                  zellij.enable = true;
                  zsh.enable = true;
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
            )
            ++ lib.optionals osConfig.services.xserver.desktopManager.gnome.enable [
              ../../../hm/donteatoreo/dconf.nix
            ];
        in
        config;
    };
}
