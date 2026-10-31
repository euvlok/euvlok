{
  homeManagerModule,
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
        "Match host tenjin.com localnetwork 192.168.50.0/24" = {
          # Use the Wi-Fi router's WireGuard tunnel instead of Tailscale's
          # advertised host route, which does not permit SSH to this address.
          ProxyCommand = "/usr/bin/nc -4 -b en0 -G 10 %h %p";
        };
        "www.tenjin-dk.com" = {
          # Bypass intermittent macOS DNS stalls for the public SSH endpoint.
          HostName = lib.mkForce "188.34.136.238";
          HostKeyAlias = "[www.tenjin-dk.com]:57255";
        };
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
      linearmouse
      mole-cleaner
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
      # audacity
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
      osu-lazer-bin
      prismlauncher
      ryubing
      winetricks
      xemu
      ;
  };

  allPackages =
    macosPackages
    ++ socialPackages
    ++ multimediaPackages
    ++ authPackages
    ++ productivityPackages
    ++ gamingPackages
    ++ (lib.attrsets.attrValues { inherit (pkgs.jetbrains) rider clion idea; });

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
