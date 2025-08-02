{
  inputs,
  pkgs,
  lib,
  config,
  euvlok,
  pkgsUnstable,
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
    extraSpecialArgs = {
      inherit
        inputs
        release
        euvlok
        pkgsUnstable
        ;
    };
  };

  home-manager.users.faputa =
    { config, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
      ]
      ++ [
        ../../../hm/donteatoreo/nushell.nix
        ../../../hm/donteatoreo/starship.nix
        ../../../hm/bigshaq9999/git.nix
      ]
      ++ [
        inputs.catppuccin-trivial.homeModules.catppuccin
        {
          catppuccin = {
            enable = true;
            flavor = "frappe";
            accent = "rosewater";
          };
          home = {
            file."Documents/development/catppuccin/catppuccin-userstyles.json".source =
              (pkgs.callPackage ../../../../pkgs/catppuccin-userstyles.nix {
                inherit (config.catppuccin) accent flavor;
              }).outPath
              + "/dist/import.json";
          };
        }
      ]
      ++ [
        ../../../hm/ashuramaruzxc/nixcord.nix
        {
          programs.nixcord.discord.vencord.unstable = lib.mkForce false;
          programs.nixcord.discord.vencord.package = lib.mkForce (
            (inputs.nixcord-trivial.packages.aarch64-darwin.vencord.override {
              unstable = true;
            }).overrideAttrs
              (oldAttrs: {
                pnpmDeps = pkgs.pnpm_10.fetchDeps {
                  inherit (oldAttrs) pname src;
                  hash = "sha256-QiD4qTRtz5vz0EEc6Q08ej6dbVGMlPLU2v0GVKNBQyc=";
                  fetcherVersion = 9;
                };
              })
          );
        }
      ]
      ++ [
        ../../../hm/ashuramaruzxc/vscode.nix
        {
          programs.vscode = {
            profiles.default = {
              userSettings = {
                "editor.fontSize" = lib.mkForce 13;
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
            age.keyFile = ''/Users/faputa/Library/Application Support/sops/age/keys.txt'';
            defaultSopsFile = ../../../../secrets/bigshaq9999.yaml;
          };
        }
      ]
      ++ [
        ../../../../modules/hm
        {
          hm = {
            fastfetch.enable = true;
            firefox.enable = true;
            firefox.floorp.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            nvf.enable = true;
            vscode.enable = true;
            yazi.enable = true;
            zellij.enable = true;
          };
        }
      ]
      ++ [
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
              notion-app # Productivity
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
