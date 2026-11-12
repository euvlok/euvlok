{
  homeManagerModule,
  personalModule,
  sharedModule,
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
      nushell.enable = true;
      zsh.enable = true;
      helix.defaultEditor = true;
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
      helix.enable = true;
      nixcord.enable = true;
      vscode.enable = true;
      yazi.enable = true;
    };
  };
}
