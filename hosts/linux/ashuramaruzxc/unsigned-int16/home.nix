{
  animeCursorsSource,
  catppuccinModule,
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
    { home.stateVersion = "26.05"; }
    catppuccinModule
  ];

  ashuramaruHmConfig = [
    ../../../hm/ashuramaruzxc/workstation.nix
  ];

  allPackages = homePackages.mkPackages [
    "important"
    "multimedia"
    "productivity"
    "social"
    "networking"
    "audio"
  ];
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
  };

  home-manager.users.ashuramaru = {
    imports =
      baseImports
      ++ [
        { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int16.yaml; }
      ]
      ++ ashuramaruHmConfig
      ++ [
        { home.packages = allPackages; }
        cursorModule
      ];
  };
}
