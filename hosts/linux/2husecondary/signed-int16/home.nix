{
  inputs,
  lib,
  pkgs,
  config,
  eulib,
  pkgsUnstable,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-2husecondary.nixosModules.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.reisen =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "25.05"; }
          inputs.catppuccin-trivial.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../../../hm/2husecondary/firefox.nix
          ../../../hm/2husecondary/flatpak.nix
          ../../../hm/2husecondary/git.nix
          ../../../hm/ashuramaruzxc/nixcord.nix
          ../../../hm/ashuramaruzxc/vscode.nix
          ../../../hm/ashuramaruzxc/starship.nix
          #../../../hm/donteatoreo/nushell.nix
          inputs.sops-nix-trivial.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "/Users/reisen/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/2husecondary.yaml;
            };
          }

          ../../../../modules/hm
          {
            hm = {
              chromium.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              ghostty.enable = true;
              mpv.enable = true;
              nixcord.enable = true;
              nvf.enable = true;
              vscode.enable = true;
              zellij.enable = true;
            };
          }

          {
            home.packages = builtins.attrValues {
              inherit (pkgs)
                # Audio
                tenacity
                pavucontrol
                qpwgraph

                # Graphics
                gimp
                inkscape

                # Media
                quodlibet-full
                vlc
                yt-dlp
                brasero
                cdrtools

                # Office
                libreoffice-fresh

                # Communication
                element-desktop
                thunderbird
                keepassxc

                # Utils
                nextcloud-client
                qbittorrent
                flameshot
                unetbootin
                woeusb-ng
                fsearch
                obsidian
                ;
              inherit (pkgsUnstable) tdesktop;
            };
            programs = {
              gpg = {
                enable = true;
                settings.no-symkey-cache = true;
              };
              gallery-dl = {
                enable = true;
                settings.extractor.base-directory = "~/Downloads/gallery-dl";
              };
              btop.enable = true;
            };
          }
        ];
      };
    extraSpecialArgs = {
      inherit
        inputs
        release
        eulib
        pkgsUnstable
        ;
    };
  };
}
