{
  inputs,
  pkgs,
  lib,
  eulib,
  ...
}:
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.faputa =
    { config, ... }:
    {
      imports = [
        { home.stateVersion = "25.11"; }
      ]
      ++ [
        ../../../hm/flameflag/nushell.nix
        ../../../hm/flameflag/starship.nix
        ../../../hm/bigshaq9999/git.nix
        ../../../hm/bigshaq9999/helix.nix
        ../../../hm/bigshaq9999/ghostty.nix
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
        ../../../hm/ashuramaruzxc/nixcord.nix
      ]
      ++ [
        ../../../hm/ashuramaruzxc/vscode.nix
        {
          programs.vscode = {
            profiles.default = {
              userSettings = {
                "editor.fontSize" = lib.mkForce 15;
                "editor.tabSize" = lib.mkForce 4;
                "editor.fontFamily" = lib.mkForce "'Hack Nerd Font Mono'";
                "terminal.integrated.fontFamily" = lib.mkForce "'Hack Nerd Font Mono'";
              };
            };
          };
        }
      ]
      ++ [
        inputs.sops-nix-trivial.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "${config.home.homeDirectory}/Library/Application Support/sops/age/keys.txt";
            defaultSopsFile = ../../../../secrets/bigshaq9999.yaml;
          };
        }
      ]
      ++ [
        inputs.self.homeModules.default
        inputs.self.homeModules.os
        inputs.self.homeConfigurations.bigshaq9999
        ../../../hm/flameflag/nushell.nix
        ../../../hm/flameflag/starship.nix
        {
          hm = {
            fastfetch.enable = true;
            firefox.enable = true;
            firefox.zen-browser.enable = true;
            ghostty.enable = true;
            helix.enable = true;
            mpv.enable = true;
            nh.enable = true;
            nixcord.enable = true;
            # nushell.enable = true;
            vscode.enable = true;
            # yazi.enable = true;
            zed-editor.enable = true;
            zellij.enable = true;
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
            inherit (pkgs) signal-desktop-bin;

            # Utilities
            inherit (pkgs)
              qbittorrent
              anki-bin # Japenis
              audacity
              # gimp # Image editing
              inkscape # Vector graphics
              yubikey-manager # OTP
              notion-app # Productivity
              # mullvad-vpn
              ;

            inherit (pkgs)
              # nicotine-plus # Broken?
              prismlauncher
              ;
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
