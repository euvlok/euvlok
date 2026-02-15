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

  home-manager.users.bruno =
    { pkgs, osConfig, ... }:
    {
      imports = [
        ./packages.nix
        {
          home.stateVersion = "25.11";
          programs.zed-editor.package = pkgs.zed-editor;

        }
      ]
      ++ [
        inputs.self.homeModules.default
        inputs.self.homeModules.os
        inputs.self.homeConfigurations.sm-idk
        ../../../../modules/hm/wm/niri
        {
          hm = {
            git.enable = true;
            chromium.enable = true;
            zed-editor.enable = true;
            ghostty.enable = true;
            bash.enable = true;
            nixcord.enable = true;
            niri.enable = true;
            firefox.zen-browser.enable = true;
          };
        }
      ];
    };
}
