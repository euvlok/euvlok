{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.self.homeModules.default
    inputs.self.homeModules.os
    inputs.self.homeConfigurations.sm-idk
    ./modules
  ];

  home.packages =
    (builtins.attrValues {
      inherit (pkgs)
        btop
        file
        ghostty
        ;

      inherit (pkgs.unstable)
        gnome-frog
        mpv
        transmission_4-qt
        yt-dlp
        ;
    })
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
      builtins.attrValues {
        inherit (pkgs.unstable)
          bottles
          imhex
          onlyoffice-desktopeditors
          prismlauncher
          rpcs3
          signal-desktop
          ;

        helium = inputs.eupkgs.legacyPackages.${pkgs.system}.helium-browser;
        octave = pkgs.octaveFull.withPackages (p: [ p.symbolic ]);
      }
    );

  programs.bash.enable = true;
  programs.home-manager.enable = true;

  # The version should stay at the version you originally installed.
  home.stateVersion = "25.05";
}
