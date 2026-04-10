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
        vscode.enable = true;
        zellij.enable = true;
        zsh.enable = true;
        languages = {
          cpp.enable = true;
          # csharp.enable = true;
          # csharp.version = "8";
          go.enable = true;
          haskell.enable = true;
          java.enable = true;
          java.version = "17";
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
      "nemo"
    ]
    ++ [ pkgs.protonvpn-cli ];
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
        inputs.sops-nix-trivial.homeManagerModules.sops
        # {
        #   sops = {
        #     age.keyFile = "$HOME/.config/sops/age/keys.txt";
        #     defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
        #   };
        # }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { services.protonmail-bridge.enable = true; }
        { home.packages = allPackages; }
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
            btop.enable = true;
            direnv.nix-direnv.package = pkgs.unstable.nix-direnv;
          };
        }
      ];
  };
}
