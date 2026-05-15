{
  inputs,
  pkgs,
  ...
}:
let
  homePackages = import ../shared/home/packages.nix { inherit pkgs; };
  cursorModule = import ../shared/home/cursor.nix {
    cursorName = "touhou-reimu";
    cursorPackage = inputs.anime-cursors-source.packages.${pkgs.stdenvNoCC.hostPlatform.system}.cursors;
    iconPackage = pkgs.unstable.kdePackages.breeze-icons;
  };

  baseImports = [
    { home.stateVersion = "26.05"; }
    ../../../../modules/hm/catppuccin-gtk.nix
  ];

  catppuccinConfig =
    { osConfig, ... }:
    {
      catppuccin = {
        inherit (osConfig.catppuccin) enable accent flavor;
        sources.gitui = "${
          builtins.fetchTree {
            type = "github";
            owner = "catppuccin";
            repo = "gitui";
            rev = "df2f59f847e047ff119a105afff49238311b2d36";
            narHash = "sha256-DRK/j3899qJW4qP1HKzgEtefz/tTJtwPkKtoIzuoTj0=";
          }
        }/themes";
      };
    };

  ashuramaruHmConfig = [
    inputs.self.homeModules.default
    inputs.self.homeModules.os
    inputs.self.homeConfigurations.ashuramaruzxc
    ../../../hm/ashuramaruzxc/chromium
    {
      hm = {
        fastfetch.enable = true;
        firefox = {
          zen-browser.enable = true;
          defaultSearchEngine = "kagi";
        };
        ghostty.enable = true;
        helix.enable = true;
        mpv.enable = true;
        nh.enable = true;
        zed-editor.enable = true;
        zellij.enable = true;
        zsh.enable = true;
        languages = {
          cpp.enable = true;
          csharp.enable = true;
          csharp.version = "10";
          go.enable = true;
          haskell.enable = true;
          java.enable = true;
          java.version = "25";
          javascript.enable = true;
          kotlin.enable = true;
          lisp.enable = true;
          lua.enable = true;
          python.enable = true;
          ruby.enable = true;
          rust.enable = true;
          scala.enable = true;
        };
      };
    }
  ];

  allPackages = homePackages.mkPackages [ ];
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs; };
  };

  home-manager.users.ashuramaru = {
    imports =
      baseImports
      ++ [
        catppuccinConfig
        { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml; }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { home.packages = allPackages; }
        cursorModule
        {
          services.protonmail-bridge.enable = true;
          programs = {
            rbw = {
              enable = true;
              settings = {
                email = "ashuramaru@tenjin-dk.com";
                base_url = "https://bitwarden.tenjin-dk.com";
                lock_timeout = 600;
                pinentry = pkgs.pinentry-qt;
              };
            };
            ghostty.settings = {
              window-height = 40;
              window-width = 140;
            };
            btop.enable = true;
            direnv.nix-direnv.package = pkgs.unstable.nix-direnv;
          };
        }
      ];
  };
}
