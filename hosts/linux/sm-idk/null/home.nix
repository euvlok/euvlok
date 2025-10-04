{
  inputs,
  pkgsUnstable,
  eulib,
  ...
}:
{
  imports = [ inputs.home-manager-sm-idk.nixosModules.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs pkgsUnstable eulib; };
  };

  home-manager.users.bruno =
    { pkgs, osConfig, ... }:
    {
      imports =
        let
          modulesImports = [
            { home.stateVersion = "25.05"; }
            inputs.catppuccin-trivial.homeModules.catppuccin
            { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
            ../../../../modules/hm
            ../../../hm/sm-idk/git.nix
            ../../../../modules/hm/wm/niri
            ./packages.nix
          ];
          programs = [
            {
              programs.zed-editor.package = pkgs.zed-editor_git;
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
        in
        modulesImports ++ programs;
    };
}
