{
  inputs,
  pkgs,
  lib,
  eulib,
  ...
}:
let
  commonImports = [
    { home.stateVersion = "25.11"; }
    ../../../hm/ashuramaruzxc/aliases.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/helix.nix
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/ssh.nix
    ../../../hm/ashuramaruzxc/starship.nix
  ];

  catppuccinConfig = {
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "flamingo";
    };
  };

  hmModuleConfig = [
    inputs.self.homeModules.default
    inputs.self.homeModules.os
    inputs.self.homeConfigurations.ashuramaruzxc
    {
      hm = {
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
        # nushell.enable = true;
        vscode.enable = true;
        zed-editor.enable = true;
        zellij.enable = true;
        languages = {
          # cpp.enable = true;
          csharp = {
            enable = true;
            version = "10";
          };
          go.enable = true;
          haskell.enable = true;
          java = {
            enable = true;
            version = "21";
          };
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

  sopsConfig = [
    inputs.sops-nix-trivial.homeManagerModules.sops
    {
      sops = {
        age.keyFile = "$HOME/.config/sops/age/keys.txt";
        defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml;
      };
    }
  ];

  macosPackages = builtins.attrValues {
    inherit (pkgs.unstable)
      alt-tab-macos
      ice-bar
      iina
      raycast
      shottr
      stats
      ;
  };

  socialPackages = builtins.attrValues {
    inherit (pkgs) signal-desktop-bin materialgram;
  };

  multimediaPackages = builtins.attrValues {
    inherit (pkgs)
      anki-bin
      audacity
      inkscape
      nicotine-plus
      qbittorrent
      yubikey-manager
      ;
    inherit (pkgs.eupkgs) helium-browser;
  };

  gamingPackages = builtins.attrValues {
    inherit (pkgs.unstable)
      chiaki
      prismlauncher
      ryubing
      winetricks
      xemu
      ;
    inherit (pkgs.jetbrains) dataspell datagrip;
    pcsx2-bin = pkgs.pcsx2-bin.overrideAttrs (oldAttrs: {
      meta = lib.recursiveUpdate oldAttrs.meta { platforms = lib.platforms.darwin; };
    });
  };

  jetbrainsPackages =
    let
      inherit (pkgs.unstable.jetbrains) rider clion idea;
      # inherit (pkgs.jetbrains.plugins) addPlugins;
      # commonPlugins = [
      #   "better-direnv"
      #   "catppuccin-icons"
      #   "catppuccin-theme"
      #   "csv-editor"
      #   "ini"
      #   "nixidea"
      #   "rainbow-brackets"
      # ];
    in
    [
      rider
      clion
      idea
    ];
  # builtins.attrValues {
  #   riderWithPlugins = addPlugins rider (commonPlugins ++ [ "python-community-edition" ]);
  #   clionWithPlugins = addPlugins clion (commonPlugins ++ [ "rust" ]);
  #   ideaUltimateWithPlugins = addPlugins idea-ultimate (
  #     commonPlugins ++ [ "go" "minecraft-development" "python" "rust" "scala" ]
  #   );
  # };

  allPackages =
    macosPackages ++ socialPackages ++ multimediaPackages ++ gamingPackages ++ jetbrainsPackages;

  userExtras = [
    { home.packages = allPackages; }
    {
      programs = {
        btop.enable = true;
        gitui.enable = lib.mkForce false;
        rbw = {
          enable = true;
          settings = {
            email = "ashuramaru@tenjin-dk.com";
            base_url = "bitwarden.tenjin-dk.com";
            lock_timeout = 600;
            pinentry = pkgs.pinentry_mac;
          };
        };
      };
    }
  ];

  mkUserImports = commonImports ++ [ catppuccinConfig ] ++ sopsConfig ++ hmModuleConfig ++ userExtras;
in
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs eulib; };
    users.ashuramaru.imports = mkUserImports;
    users.faputa.imports = mkUserImports;
  };
}
