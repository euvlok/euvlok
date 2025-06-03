{
  inputs,
  config,
  lib,
  euvlok,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-bigshaq9999.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nanachi =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../../../hm/bigshaq9999/niri.nix
          ../../../hm/bigshaq9999/taskwarrior.nix
          ../../../hm/bigshaq9999/waybar.nix

          ../../../hm/donteatoreo/mpv.nix
          ../../../hm/donteatoreo/nixcord.nix
          ../../../hm/donteatoreo/starship.nix
          ../../../hm/donteatoreo/yazi.nix

          ../../../../modules/hm
          ../../../../modules/hm/wm/niri
          {
            hm = {
              bash.enable = true;
              chromium.browser = "brave";
              chromium.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              firefox.floorp.enable = true;
              fzf.enable = true;
              ghostty.enable = true;
              git.enable = true;
              helix.enable = true;
              mpv.enable = true;
              niri.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              nvf.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zsh.enable = true;
            };
          }

          {
            services.macos-remap-keys.enable = true;
            services.macos-remap-keys.keyboard = {
              Capslock = "Escape";
              Escape = "Capslock";
            };
          }
        ];
      };
    extraSpecialArgs = { inherit inputs release euvlok; };
  };
}
