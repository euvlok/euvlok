{
  inputs,
  pkgs,
  eulib,
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
    { home.stateVersion = "25.11"; }
    ../../../../modules/hm/catppuccin-gtk.nix
  ];

  catppuccinConfig =
    { osConfig, ... }:
    {
      catppuccin = {
        inherit (osConfig.catppuccin) enable accent flavor;
      };
    };

  rootHmConfig = {
    hm = {
      bash.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      helix.enable = true;
      nh.enable = true;
      zellij.enable = true;
      zsh.enable = true;
    };
  };

  ashuramaruHmConfig = [
    inputs.self.homeModules.default
    inputs.self.homeModules.os
    inputs.self.homeConfigurations.ashuramaruzxc
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/chromium
    # ../../../hm/ashuramaruzxc/flatpak.nix
    {
      hm = {
        chromium.enable = true;
        fastfetch.enable = true;
        firefox = {
          floorp.enable = true;
          zen-browser.enable = true;
          defaultSearchEngine = "kagi";
        };
        ghostty.enable = true;
        helix.enable = true;
        mpv.enable = true;
        nh.enable = true;
        nixcord.enable = true;
        nushell.enable = true;
        vscode.enable = true;
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
          java.version = "21";
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

  allPackages =
    homePackages.mkPackages [
      "important"
      "multimedia"
      "productivity"
      "social"
      "networking"
      "audio"
      "gaming"
      "development"
      "jetbrains"
      "nemo"
    ]
    ++ [ pkgs.unstable.piper ];
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.root = {
    imports =
      baseImports
      ++ [
        catppuccinConfig
        rootHmConfig
      ]
      ++ ashuramaruHmConfig;
  };

  home-manager.users.ashuramaru = {
    imports =
      baseImports
      ++ [
        catppuccinConfig
        { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml; }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { services.protonmail-bridge.enable = true; }
        { home.packages = allPackages; }
        (
          {
            inputs,
            lib,
            ...
          }:
          {
            # doesn't work with cudaEnable = true;
            home.packages = builtins.attrValues {
              inherit (inputs.nixpkgs.legacyPackages.${pkgs.stdenvNoCC.hostPlatform.system}) rpcs3;
            };
          }
        )
        cursorModule
        {
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
