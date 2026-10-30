{
  aiModule,
  animeCursorsPackage,
  catppuccinModule,
  codexDesktopModule,
  homeManagerModule,
  jetbrainsPlugins,
  personalModule,
  sharedModule,
}:
{
  lib,
  pkgs,
  ...
}:
let
  homePackages = import ../shared/home/packages.nix { inherit pkgs lib jetbrainsPlugins; };
  cursorPackage = animeCursorsPackage pkgs;
  cursorModule = lib.modules.importApply ../shared/home/cursor.nix {
    inherit cursorPackage;
    cursorName = cursorPackage.themeName;
    iconPackage = pkgs.unstable.kdePackages.breeze-icons;
  };

  baseImports = [
    { home.stateVersion = "26.11"; }
    catppuccinModule
  ];

  ashuramaruHmConfig = [
    aiModule
    codexDesktopModule
    (import ../../../../slop.nix).homeManager.codex
    (import ../../../../slop.nix).homeManager.claude-code
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/workstation.nix
    ({ config, ... }: {
      sops.secrets.context7_api_key = { };
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
        cliPackage = config.euvlok.home.codex.package;
      };

      programs.ai = {
        omp.enable = true;
        farstep = {
          enable = true;
          desktop.enable = true;
        };
      };
      euvlok.home.nixcord.enable = true;
    })
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
    ]
    ++ [
      pkgs.unstable.piper
      # until euroffice is statble
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
        {
          sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_shared.yaml;
          sops.secrets.gitlab_token = { };
          sops.secrets.gitlab_host = { };
        }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { home.packages = allPackages; }
        cursorModule
        {
          services.easyeffects = {
            enable = true;
            package = pkgs.easyeffects.override { qt6 = pkgs.kdePackages; };
          };
        }
      ];
  };
}
