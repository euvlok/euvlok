{ inputs, config, ... }:
{
  imports = [ inputs.flatpak-declerative-trivial.homeModule ];

  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
      "moe-launcher" = "https://gol.launcher.moe/gol.launcher.moe.flatpakrepo";
    };
    packages = [
      # Desktop
      "flathub:app/com.github.tchx84.Flatseal//stable" # Easier permission manager
      "flathub:app/com.usebottles.bottles//stable"
      #
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08"
    ];
    overrides = {
      "global" = {
        filesystems = [
          "xdg-config/flatpak-gtk:ro"
          "xdg-data/icons:ro"
          "xdg-data/themes:ro"
          "xdg-config/gtk-3.0"
          "xdg-config/gtk-4.0"
          "xdg-download:rw"
          "xdg-pictures:rw"
          "xdg-run/app/com.discordapp.Discord:create"
        ];
        environment = {
          "GTK_CSD" = 0;
          "GTK_THEME" = config.gtk.theme.name or "catppuccin-mocha-flamingo-standard+rimless,normal";
          "GTK2_RC_FILES" = "${config.home.homeDirectory}/.gtkrc-2.0";
        };
      };
      "com.usebottles.bottles" = {
        sockets = [ "pcsc" ];
        filesystems = [
          "xdg-data/Steam:rw"
          "xdg-data/games:rw"
          "xdg-config/MangoHud:ro"
          "/Shared/games"
        ];
        environment = {
          "GTK_USE_PORTAL" = 0;
        };
      };
      "sh.ppy.osu" = {
        filesystems = [
          "xdg-data/Steam:rw"
          "xdg-data/games:rw"
          "xdg-config/MangoHud:ro"
        ];
      };
    };
  };
}
