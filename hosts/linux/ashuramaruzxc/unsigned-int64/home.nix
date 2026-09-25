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
    programs.bash.enable = true;
    programs.direnv.enable = true;
    programs.fastfetch.enable = true;
    programs.fzf.enable = true;
    programs.nh.enable = true;
    programs.zsh.enable = true;
    euvlok.home = {
      helix.enable = true;
      yazi.enable = true;
    };
  };

  serverHmConfig = {
    programs.fastfetch.enable = true;
    programs.nh.enable = true;
    euvlok.home = {
      helix.enable = true;
      yazi.enable = true;
    };
  };

  workstationHmConfig = [
    {
      programs.fastfetch.enable = true;
      programs.ghostty.enable = true;
      programs.nh.enable = true;
      euvlok.home = {
        helix.enable = true;
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
