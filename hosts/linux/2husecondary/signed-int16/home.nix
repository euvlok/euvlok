{
  inputs,
  pkgs,
  config,
  ...
}:
let
  release =
    if builtins.hasAttr "darwinRelease" config.system then
      builtins.fromJSON (config.system.darwinRelease)
    else
      builtins.fromJSON (config.system.nixos.release);
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
          { home.stateVersion = "24.11"; }
          inputs.catppuccin.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }

          ../../../hm/2husecondary/firefox.nix
          ../../../hm/2husecondary/flatpak.nix
          ../../../hm/2husecondary/git.nix
          ../../../hm/ashuramaruzxc/nixcord.nix
          ../../../hm/ashuramaruzxc/vscode.nix
          ../../../hm/ashuramaruzxc/starship.nix
          ../../../hm/donteatoreo/nushell.nix
          inputs.sops-nix.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "/Users/marie/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/2husecondary.yaml;
            };
          }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              chromium.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              fzf.enable = true;
              ghostty.enable = true;
              git.enable = true;
              mpv.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              nvf.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              zellij.enable = true;
              zsh.enable = true;
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
              inherit (pkgs.unstable) tdesktop;
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
    extraSpecialArgs = { inherit inputs release; };
  };
}
