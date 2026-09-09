{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.euvlok.nixos.steam.enable = lib.options.mkEnableOption "Steam";

  config = lib.modules.mkIf config.euvlok.nixos.steam.enable {
    hardware.steam-hardware.enable = true;

    # nixpkgs.config replaces lists, so preserve host-specific exceptions while
    # allowing the NW.js runtime required by games using its bundled Chromium.
    nixpkgs.config.allowInsecurePredicate =
      pkg:
      builtins.elem (pkg.name or "${pkg.pname}-${pkg.version}") (
        [ "nwjs-0.102.1" ] ++ (config.nixpkgs.config.permittedInsecurePackages or [ ])
      );

    nixpkgs.overlays = [
      (_: super: { bottles = super.bottles.override { removeWarningPopup = true; }; })
    ];

    programs = {
      steam = {
        enable = true;
        extest.enable = true;
        protontricks.enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = builtins.attrValues {
          inherit (pkgs.unstable)
            proton-ge-bin
            steamtinkerlaunch
            ;
        };
        extraPackages = builtins.attrValues {
          inherit (pkgs)
            curl
            desktop-file-utils
            gamemode
            gamescope
            libkrb5
            libpng
            libpulseaudio
            libvorbis
            mangohud
            nwjs
            steamtinkerlaunch
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
        settings.custom.start = "${lib.meta.getExe pkgs.libnotify} 'GameMode started'";
        settings.custom.end = "${lib.meta.getExe pkgs.libnotify} 'GameMode ended'";
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
        ++ (lib.lists.optionals config.services.desktopManager.gnome.enable (
          builtins.attrValues { inherit (pkgs) adwsteamgtk; }
        ));
    };
  };
}
