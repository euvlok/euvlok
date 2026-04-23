{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.nixos.steam.enable = lib.mkEnableOption "Steam";

  config = lib.mkIf config.nixos.steam.enable {
    hardware.steam-hardware.enable = true;

    nixpkgs.overlays = [
      (_: super: { bottles = super.bottles.override { removeWarningPopup = true; }; })
    ];

    programs = {
      steam = {
        enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = builtins.attrValues {
          inherit (pkgs.unstable) proton-ge-bin;
        };
        extraPackages = builtins.attrValues {
          inherit (pkgs)
            curl
            desktop-file-utils
            libkrb5
            libpng
            libpulseaudio
            libvorbis
            mangohud
            nwjs
            thcrap-steam-proton-wrapper
            vkbasalt
            yad
            ;
        };
        fontPackages = builtins.attrValues {
          inherit (pkgs) wqy_zenhei source-han-sans;
        };
      };
      gamemode = {
        enable = true;
        enableRenice = true;
        settings.custom.start = "${lib.getExe pkgs.libnotify} 'GameMode started'";
        settings.custom.end = "${lib.getExe pkgs.libnotify} 'GameMode ended'";
      };
      gamescope.enable = true;
      gamescope.capSysNice = true;
    };

    environment = {
      systemPackages =
        (builtins.attrValues {
          inherit (pkgs) scummvm inotify-tools;
          inherit (pkgs) winetricks protonplus;
          inherit (pkgs.wineWow64Packages) stagingFull;
        })
        ++ (lib.optionals config.services.desktopManager.gnome.enable (
          builtins.attrValues { inherit (pkgs) adwsteamgtk; }
        ));
    };
  };
}
