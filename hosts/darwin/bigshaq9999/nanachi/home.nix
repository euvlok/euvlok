{
  inputs,
  pkgs,
  lib,
  config,
  euvlok,
  ...
}:
let
  release = builtins.fromJSON (config.system.darwinRelease);
in
{
  imports = [ inputs.home-manager-bigshaq9999.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = ".bak";
    users.faputa =
      { config, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "rosewater";
            };
          }

          ../../../hm/ashuramaruzxc/nixcord.nix
          ../../../hm/ashuramaruzxc/vscode.nix
          ../../../hm/donteatoreo/nushell.nix
          ../../../hm/donteatoreo/starship.nix

          inputs.sops-nix-trivial.homeManagerModules.sops
          {
            sops = {
              age.keyFile = ''/Users/faputa/Library/Application Support/sops/age/keys.txt'';
              defaultSopsFile = ../../../../secrets/bigshaq9999.yaml;
            };
          }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              firefox.floorp.enable = true;
              fzf.enable = true;
              git.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              nvf.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zellij.enable = true;
            };
          }

          # Misc
          {
            home = {
              file."Documents/development/catppuccin/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
                  inherit (config.catppuccin) accent flavor;
                }).outPath
                + "/dist/import.json";
            };
          }
          {
            home.packages = builtins.attrValues {
              inherit (pkgs)
                # Make macos useful
                alt-tab-macos
                ice-bar
                iina
                iterm2
                raycast
                rectangle
                ;

              # SNS
              inherit (pkgs) signal-desktop-bin;

              # Utilities
              inherit (pkgs)
                qbittorrent
                anki-bin # Japenis
                audacity
                gimp # Image editing
                inkscape # Vector graphics
                yubikey-manager # OTP
                ;

              inherit (pkgs)
                # nicotine-plus # Broken?
                prismlauncher
                ;
            };
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
            };
          }
        ];
      };
    extraSpecialArgs = {
      inherit inputs release euvlok;
    };
  };
}
