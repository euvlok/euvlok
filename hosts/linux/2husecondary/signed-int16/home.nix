{
  inputs,
  pkgs,
  eulib,
  pkgsUnstable,
  ...
}:
{
  imports = [ inputs.home-manager-2husecondary.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs eulib pkgsUnstable; };
  };

  home-manager.users.reisen =
    { osConfig, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
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
        }
      ]
      ++ [
        {
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
      ]
      ++ [
        inputs.catppuccin-trivial.homeModules.catppuccin
        { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
      ]
      ++ [
        inputs.sops-nix-trivial.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "/Users/reisen/.config/sops/age/keys.txt";
            defaultSopsFile = ../../../../secrets/2husecondary.yaml;
          };
        }
      ]
      ++ [
        inputs.self.homeModules.default
        inputs.self.homeConfigurations._2husecondary
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
      ];
    };
}
