{
  inputs,
  pkgs,
  config,
  ...
}: let
  release = builtins.fromJSON (config.system.darwinRelease);
in {
  imports = [inputs.home-manager-donteatoreo.darwinModules.home-manager];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = ".bak";
    users.faputa = {config, ...}: {
      imports = [
        {home.stateVersion = "24.11";}
        inputs.catppuccin.homeModules.catppuccin
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

        inputs.sops-nix.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "${config.home.homeDirectory}/Library/Application\ Support/sops/age/keys.txt";
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
            inherit
              (pkgs)
              # Make macos useful
              alt-tab-macos
              ice-bar # The hands of a person of roma descent packaged this
              rectangle
              raycast
              iina # frontend for ffmpeg
              iterm2 # default iterm but if it was better
              ;

            # SNS
            inherit
              (pkgs)
              signal-desktop-bin # just in case
              ;

            # Utilities
            inherit
              (pkgs)
              # blender # 3D creation suite
              # Graphics
              #! qbittorrent @ashuramaruzxc: for some reason only works on nixos-unstable
              #! obs-studio brew
              anki-bin # Japenis
              audacity
              gimp # Image editing
              inkscape # Vector graphics
              yubikey-manager # OTP
              ;
            /**
            * NOOOOOOO ❗❗❗ 🙀 😾 BUT LE PIRACY LE BAD HOW WILL SONY AND OTHER
            * MULTIBILLION CORPORATIONS MAKE MONEY OF COPYRIGHTED SONGS WHAT ABOUT THE
            * SHARE HOLDERS VALUE ❗❗❗ 🙀
            */
            inherit (pkgs) nicotine-plus;
            inherit (pkgs.unstable-small) prismlauncher;
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
    extraSpecialArgs = {inherit inputs release;};
  };
}
