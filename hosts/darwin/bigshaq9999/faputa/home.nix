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

  home-manager.users.faputa =
    { ... }:
    {
      imports = [
        { home.stateVersion = "26.05"; }
      ]
      ++ [
        {
          catppuccin = {
            enable = true;
            flavor = "frappe";
            accent = "rosewater";
          };
        }
      ]
      ++ [
        {
          programs.vscode = {
            profiles.default = {
              userSettings = {
                "editor.fontSize" = lib.modules.mkForce 15;
                "terminal.integrated.fontSize" = lib.modules.mkForce 15;
                "editor.tabSize" = lib.modules.mkForce 4;
                "editor.fontFamily" = lib.modules.mkForce "'Hack Nerd Font Mono'";
                "terminal.integrated.fontFamily" = lib.modules.mkForce "'Hack Nerd Font Mono'";
              };
            };
          };
        }
      ]
      ++ [
        { sops.defaultSopsFile = ../../../../secrets/bigshaq9999.yaml; }
      ]
      ++ [
        {
          euvlok.home = {
            chromium = {
              enable = true;
              browser = "helium-browser";
            };
            fastfetch.enable = true;
            firefox = {
              enable = true;
              acceptedLanguages = [
                "en-US"
                "en"
                "vi"
                "ja"
                "fr"
                "ru"
              ];
              languagePacks = [
                "en-US"
                "vi"
                "ja"
                "fr"
                "ru"
              ];
              zen-browser.enable = true;
            };
            ghostty.enable = true;
            helix.enable = true;
            mpv.enable = true;
            nh.enable = true;
            nixcord.enable = true;
            vscode.enable = true;
            # yazi.enable = true;
            zed-editor.enable = true;
            # zsh.enable = false;
            languages = {
              # cpp.enable = true;
              # csharp.enable = true;
              # csharp.version = "8";
              go.enable = true;
              # haskell.enable = true;
              java.enable = true;
              java.version = "25";
              javascript.enable = true;
              kotlin.enable = true;
              lisp.enable = true;
              lua.enable = true;
              python.enable = true;
              ruby.enable = true;
              # rust.enable = true;
              scala.enable = true;
            };
          };
        }
      ]
      ++ [
        {
          home.packages = builtins.attrValues {
            inherit (pkgs.unstable)
              # Make macos useful
              alt-tab-macos
              ice-bar
              iina
              iterm2
              raycast
              stats
              shottr
              ;

            # SNS
            inherit (pkgs) signal-desktop;

            # Utilities
            inherit (pkgs)
              qbittorrent
              anki-bin # Japenis
              audacity
              # gimp # Image editing
              inkscape # Vector graphics
              yubikey-manager # OTP
              notion-app # Productivity
              ;

            inherit (pkgs.eupkgs) helium-browser codex opencode;

            # Gaming
            inherit (pkgs) prismlauncher;
          };
        }
      ]
      ++ [
        {
          programs = {
            rbw = {
              enable = true;
              settings = {
                email = "bigshaq9999@protonmail.com";
                base_url = "https://bitwarden.tenjin-dk.com";
                lock_timeout = 600;
                pinentry = pkgs.pinentry_mac;
              };
            };
            btop.enable = true;
            helix.enable = true;
          };
        }
      ];
    };
}
