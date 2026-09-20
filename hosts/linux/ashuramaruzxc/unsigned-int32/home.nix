{
  animeCursorsSource,
  catppuccinModule,
  codexDesktopModule,
  homeManagerModule,
  personalModule,
  sharedModule,
}:
{
  lib,
  pkgs,
  ...
}:
let
  homePackages = import ../shared/home/packages.nix { inherit pkgs lib; };
  cursorModule = lib.modules.importApply ../shared/home/cursor.nix {
    cursorName = "touhou-reimu";
    cursorPackage = animeCursorsSource.packages.${pkgs.stdenvNoCC.hostPlatform.system}.cursors;
    iconPackage = pkgs.unstable.kdePackages.breeze-icons;
  };

  baseImports = [
    { home.stateVersion = "26.11"; }
    catppuccinModule
  ];

  ashuramaruHmConfig = [
    codexDesktopModule
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/workstation.nix
    {
      euvlok.home = {
        codex.enable = true;
        firefox.floorp.enable = true;
        nixcord.enable = true;
        vscode.enable = true;
      };

      programs.codexDesktopLinux = {
        enable = true;
        computerUseUi.enable = true;
        remoteMobileControl.enable = true;
        linuxFeatures = [
          "appshots"
          "codex-micro"
          "pet-overlay"
          "tray-usage"
          "ui-tweaks"
          "read-aloud"
        ];
        cliPackage = pkgs.eupkgs.codex;
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
    ++ [
      pkgs.unstable.piper
      #until euroffice is statble
      pkgs.unstable.softmaker-office-nx

    ];
in
{
  imports = [ homeManagerModule ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    overwriteBackup = true;
    sharedModules = [
      sharedModule
      personalModule
    ];
  };

  home-manager.users.ashuramaru = {
    imports =
      baseImports
      ++ [
        { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int32.yaml; }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { home.packages = allPackages; }
        cursorModule
        {
          services.easyeffects.enable = true;
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
