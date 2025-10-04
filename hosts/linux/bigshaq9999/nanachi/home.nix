{
  inputs,
  config,
  eulib,
  pkgsUnstable,
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
    extraSpecialArgs = {
      inherit
        inputs
        release
        eulib
        pkgsUnstable
        ;
    };
  };

  home-manager.users.nanachi =
    { osConfig, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
      ]
      ++ [
        inputs.catppuccin-trivial.homeModules.catppuccin
        { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
      ]
      ++ [
        ../../../hm/bigshaq9999/niri.nix
        ../../../hm/bigshaq9999/taskwarrior.nix
        ../../../hm/bigshaq9999/waybar.nix
        ../../../hm/flameflag/mpv.nix
        ../../../hm/flameflag/nixcord.nix
        ../../../hm/flameflag/starship.nix
        ../../../hm/flameflag/yazi.nix
      ]
      ++ [
        ../../../../modules/hm
        ../../../../modules/hm/wm/niri
        {
          hm = {
            chromium.browser = "brave";
            chromium.enable = true;
            fastfetch.enable = true;
            firefox.enable = true;
            firefox.floorp.enable = true;
            ghostty.enable = true;
            helix.enable = true;
            mpv.enable = true;
            niri.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            nvf.enable = true;
            vscode.enable = true;
            yazi.enable = true;
          };
        }
      ]
      ++ [
        {
          services.macos-remap-keys.enable = true;
          services.macos-remap-keys.keyboard = {
            Capslock = "Escape";
            Escape = "Capslock";
          };
        }
      ];
    };
}
