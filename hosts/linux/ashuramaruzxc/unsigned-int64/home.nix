{
  catppuccinModule,
  coreModule,
  homeManagerModule,
  personalModule,
  serverModule,
  serverPersonalModule,
  sharedModule,
}:
_:
let
  baseImports = [
    { home.stateVersion = "26.05"; }
  ];

  workstationImports = [
    catppuccinModule
    sharedModule
    personalModule
  ];

  rootHmConfig = {
    euvlok.home = {
      bash.enable = true;
      direnv.enable = true;
      fastfetch.enable = true;
      fzf.enable = true;
      helix.enable = true;
      nh.enable = true;
      yazi.enable = true;
      zsh.enable = true;
    };
  };

  serverHmConfig = {
    euvlok.home = {
      fastfetch.enable = true;
      helix.enable = true;
      nh.enable = true;
      yazi.enable = true;
    };
  };

  workstationHmConfig = [
    {
      euvlok.home = {
        fastfetch.enable = true;
        ghostty.enable = true;
        helix.enable = true;
        nh.enable = true;
        vscode.enable = true;
        yazi.enable = true;
      };
    }
  ];

  globalImports = [
    ../shared/home/aliases.nix
    { sops.defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml; }
  ];
in
{
  imports = [ homeManagerModule ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "bak";
    sharedModules = [ coreModule ];
  };

  home-manager.users.root = {
    imports =
      baseImports
      ++ [
        serverModule
        serverPersonalModule
      ]
      ++ globalImports
      ++ [ rootHmConfig ];
  };

  home-manager.users.ashuramaru = {
    imports = baseImports ++ workstationImports ++ globalImports ++ workstationHmConfig;
  };

  home-manager.users.fumono = {
    imports = baseImports ++ workstationImports ++ globalImports ++ workstationHmConfig;
  };

  home-manager.users.minecraft = {
    imports =
      baseImports
      ++ [
        serverModule
        serverPersonalModule
      ]
      ++ globalImports
      ++ [ serverHmConfig ];
  };
}
