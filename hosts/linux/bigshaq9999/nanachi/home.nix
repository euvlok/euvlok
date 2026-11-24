{
  homeManagerModule,
  personalModule,
  sharedModule,
}:
{
  pkgs,
  lib,
  ...
}:
{
  imports = [ homeManagerModule ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    sharedModules = [
      sharedModule
      personalModule
    ];
  };

  home-manager.users.nanachi = {
    home.stateVersion = "25.05";
    programs = {
      # Keep the pre-XDG profile location used by the original installation
      firefox.configPath = ".mozilla/firefox";
      fastfetch.enable = true;
      ghostty.enable = true;
      mpv.enable = true;
      nushell = {
        enable = true;
        # Keep the existing env.nu ownership
        loadSessionVariables = false;
      };
      zsh.enable = true;
    };

    catppuccin = {
      enable = true;
      flavor = "frappe";
      accent = "blue";
    };

    euvlok.home = {
      chromium = {
        enable = true;
        browser = "helium-browser";
      };
      firefox = {
        enable = true;
        floorp.enable = true;
      };
      mitos = {
        enable = true;
        defaultEditor = true;
      };
      nixcord.enable = true;
      yazi.enable = true;
    };

    home.packages = lib.attrsets.attrValues {
      inherit (pkgs)
        telegram-desktop
        ;
    };
  };
}
