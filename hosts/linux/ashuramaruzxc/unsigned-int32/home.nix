{
  animeCursorsSource,
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
  cursorModule = lib.modules.importApply ../shared/home/cursor.nix {
    cursorName = "touhou-reimu";
    cursorPackage = animeCursorsSource.packages.${pkgs.stdenvNoCC.hostPlatform.system}.cursors;
    iconPackage = pkgs.unstable.kdePackages.breeze-icons;
  };

  baseImports = [
    { home.stateVersion = "26.11"; }
    catppuccinModule
    (import ../../../../slop.nix).homeManager.hosts.linuxProductivity
  ];

  ashuramaruHmConfig = [
    ((import ../../../../slop.nix).homeManager.hosts.unsignedInt32 {
      inherit codexDesktopModule;
    })
    ../../../hm/ashuramaruzxc/graphics.nix
    ../../../hm/ashuramaruzxc/workstation.nix
    {
      euvlok.home = {
        firefox.floorp.enable = true;
        nixcord.enable = true;
        vscode.enable = true;
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
        { services.easyeffects.enable = true; }
      ];
  };
}
