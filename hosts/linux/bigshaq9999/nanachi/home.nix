{
  inputs,
  eulib,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.nanachi =
    { osConfig, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
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
        inputs.self.homeModules.default
        inputs.self.homeModules.os
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
