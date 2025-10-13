{
  inputs,
  pkgs,
  eulib,
  pkgsUnstable,
  ...
}:
let
  commonImports = [
    { home.stateVersion = "25.05"; }
    ../../../../pkgs/catppuccin-gtk.nix
    ../shared/aliases.nix
    ./packages.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
  ];
  catppuccinConfig =
    { osConfig, ... }:
    {
      catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; };
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
    ../../../linux/shared/protonmail-bridge.nix
    inputs.self.homeModules.default
    inputs.self.homeProfiles.ashuramaruzxc
    {
      hm = {
        chromium.chromium.enable = true;
        fastfetch.enable = true;
        firefox = {
          enable = true;
          floorp.enable = true;
          zen-browser.enable = true;
          defaultSearchEngine = "kagi";
        };
        ghostty.enable = true;
        helix.enable = true;
        mpv.enable = true;
        nh.enable = true;
        nushell.enable = true;
        # yazi.enable = true;
        zellij.enable = true;
        zsh.enable = true;
      };
    }
  ];
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs eulib pkgsUnstable; };
  };

  home-manager.users.root.imports = commonImports ++ [
    catppuccinConfig
    rootHmConfig
  ];

  home-manager.users.ashuramaru.imports =
    commonImports
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
      (
        {
          inputs,
          config,
          lib,
          osConfig,
          ...
        }:
        {
          # doesn't work with cudaEnable = true;
          home.pointerCursor = {
            enable = true;
            name = "touhou-reimu";
            package = inputs.anime-cursors-source.packages.${osConfig.nixpkgs.hostPlatform.system}.cursors;
            size = 32;
            gtk.enable = true;
            x11 = {
              enable = true;
              defaultCursor = "touhou-reimu";
            };
          };
          gtk = {
            enable = true;
            iconTheme = {
              name = lib.mkForce "breeze-dark";
              package = lib.mkForce pkgs.kdePackages.breeze-icons;
            };
          };
          catppuccin.i-still-want-to-use-the-archived-gtk-theme-because-it-works-better-than-everything-else = {
            enable = true;
            inherit (osConfig.catppuccin) accent flavor;
            size = "standard";
            tweaks = [
              "rimless"
              "normal"
            ];
          };
          home.sessionVariables = {
            GTK_CSD = "0";
            GO_PATH = "${config.home.homeDirectory}/.go";
            GEM_HOME = "${config.home.homeDirectory}/.gems";
            GEM_PATH = "${config.home.homeDirectory}/.gems";
          };
          services.easyeffects.enable = true;
        }
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
          btop.enable = true;
        };
      }
    ];
}
