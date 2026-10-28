{
  homeManagerModule,
  jetbrainsPlugins,
  personalModule,
  raycastModule,
  raycastPackage,
  sharedModule,
}:
{ lib, pkgs, ... }:
let
  commonImports = [
    { home.stateVersion = "26.11"; }
    (import ../../../../slop.nix).homeManager.hosts.unsignedInt8
    ../../../hm/ashuramaruzxc/aliases.nix
    ../../../hm/ashuramaruzxc/git.nix
    ../../../hm/ashuramaruzxc/helix.nix
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
    {
      programs.ssh.settings = {
        "unsigned-int32" = {
          HostName = "unsigned-int32";
          ProxyCommand = "${lib.getExe' pkgs.tailscale "tailscale"} --socket=/var/run/tailscaled.socket nc %h %p";
          User = "ashuramaru";
        };
        "unsigned-int64" = {
          HostName = "unsigned-int64";
          Port = 57255;
          ProxyCommand = "${lib.getExe' pkgs.tailscale "tailscale"} --socket=/var/run/tailscaled.socket nc %h %p";
          User = "ashuramaru";
        };
      };
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        enableSshSupport = false;
      };
      programs.nix-index.enable = true;
      programs.fastfetch.enable = true;
      programs.ghostty.enable = true;
      programs.mpv.enable = true;
      programs.nh.enable = true;
      euvlok.home = {
        firefox = {
          zen-browser.enable = true;
          defaultSearchEngine = "kagi";
        };
        helix.enable = true;
        nixcord.enable = true;
        yazi.enable = true;
        zed-editor.enable = true;
        zellij.enable = true;
        languages = {
          cpp.enable = true;
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
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_shared.yaml; }
  ];

  macosPackages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      alt-tab-macos
      betterdisplay
      iina
      orbstack
      shottr
      thaw
      the-unarchiver
      ;
    inherit (pkgs.eupkgs) aldente;
  };

  socialPackages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      signal-desktop
      telegram-desktop
      whatsapp-for-mac
      ;
  };

  multimediaPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      nicotine-plus
      qbittorrent
      ;
  };
  productivityPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      anki-bin
      inkscape
      audacity
      ;
    inherit (pkgs.eupkgs) helium-browser;
  };

  authPackages = lib.attrsets.attrValues {
    inherit (pkgs)
      keepassxc
      yubikey-manager
      ;
  };

  gamingPackages = lib.attrsets.attrValues {
    inherit (pkgs.unstable)
      chiaki
      osu-lazer-bin
      prismlauncher
      ryubing
      winetricks
      xemu
      ;
    inherit (jetbrainsPackages) dataspell;
  };

  jetbrainsPackages = import ../../../hm/ashuramaruzxc/jetbrains.nix {
    inherit jetbrainsPlugins;
    pkgs = pkgs.unstable;
  };

  allPackages =
    macosPackages
    ++ socialPackages
    ++ multimediaPackages
    ++ authPackages
    ++ productivityPackages
    ++ gamingPackages
    ++ (lib.attrsets.attrValues { inherit (jetbrainsPackages) rider clion idea; });

  userExtras = [
    { home.packages = allPackages; }
    {
      programs = {
        btop.enable = true;
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

  ashuramaru = commonImports ++ [ catppuccinConfig ] ++ sopsConfig ++ hmModuleConfig ++ userExtras;
in
{
  imports = [ homeManagerModule ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    sharedModules = [
      sharedModule
      personalModule
    ];
    users.ashuramaru.imports = [
      (import ../../../../modules/hm/gui/raycast.nix {
        avatarId = "72100551";
        fallbackName = "ashuramaruzxc";
        inherit raycastModule raycastPackage;
      })
    ]
    ++ ashuramaru;
  };
}
