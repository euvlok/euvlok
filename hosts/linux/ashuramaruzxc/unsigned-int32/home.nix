{
  inputs,
  pkgs,
  eulib,
  ...
}:
let
  homeCommon = import ../shared/home/common.nix { inherit inputs eulib; };
  homePackages = import ../shared/home/packages.nix { inherit pkgs; };
  homeBaseUsers = import ../shared/home/base-users.nix {
    inherit (homeCommon) baseImports baseHomeManager;
  };

  cursorModule = import ../shared/home/cursor.nix {
    cursorName = "touhou-reimu";
    cursorPackage = inputs.anime-cursors-source.packages.${pkgs.stdenv.hostPlatform.system}.cursors;
    iconPackage = pkgs.kdePackages.breeze-icons;
  };

  inherit (homeCommon) catppuccinConfig rootHmConfig;

  ashuramaruHmConfig = [
    inputs.self.homeModules.default
    inputs.self.homeConfigurations.ashuramaruzxc
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/chromium
    # ../../../hm/ashuramaruzxc/flatpak.nix
    {
      hm = {
        chromium.enable = true;
        chromium.browser = "chromium";
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

  # globalImports = [ ../shared/aliases.nix ];

  userImports = {
    root = [
      catppuccinConfig
      rootHmConfig
    ]
    ++ ashuramaruHmConfig;

    ashuramaru = [
      catppuccinConfig
      inputs.sops-nix-trivial.homeManagerModules.sops
      {
        sops = {
          age.keyFile = "$HOME/.config/sops/age/keys.txt";
          defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        };
      }
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
            inherit (inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}) rpcs3;
          };
        }
      )
      (
        {
          lib,
          ...
        }:
        cursorModule { inherit lib pkgs; }
      )
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
in
homeBaseUsers {
  inherit userImports;
}
