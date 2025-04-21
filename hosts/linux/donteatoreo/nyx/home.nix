{
  inputs,
  lib,
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
  imports = [ inputs.home-manager-donteatoreo.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nyx = {
      imports =
        [
          { home.stateVersion = "24.11"; }
          { home.shellAliases = import ../../../hm/donteatoreo/aliases.nix { }; }
          inputs.catppuccin.homeModules.catppuccin
          { inherit (osConfig) catppuccin; }

          ../../../hm/donteatoreo/ghostty.nix
          ../../../hm/donteatoreo/git.nix
          ../../../hm/donteatoreo/helix.nix
          ../../../hm/donteatoreo/mpv.nix
          ../../../hm/donteatoreo/nixcord.nix
          ../../../hm/donteatoreo/nushell.nix
          ../../../hm/donteatoreo/ssh.nix
          ../../../hm/donteatoreo/starship.nix
          ../../../hm/donteatoreo/vscode.nix
          ../../../hm/donteatoreo/yazi.nix

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              chromium.browser = "brave";
              chromium.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
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
              zellij.enable = true;
              zsh.enable = true;
            };
          }
        ]
        ++ lib.optionals config.services.xserver.desktopManager.gnome.enable [
          ../../../hm/donteatoreo/dconf.nix
        ]
        ++ lib.optionals (builtins.hasAttr "sops" config) [
          inputs.sops-nix.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/donteatoreo.yaml;
              secrets.github_ssh = { };
            };
          }
        ];
    };
    extraSpecialArgs = { inherit inputs release; };
  };
}
