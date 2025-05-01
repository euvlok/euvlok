{ inputs, ... }:
{
  imports = [ inputs.flatpaks.homeManagerModules.declarative-flatpak ];

  services.flatpak = {
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      # KDE/Qt
      "flathub:app/com.github.tchx84.Flatseal/x86_64/stable"
      "flathub:app/org.kde.kdenlive/x86_64/stable"
      "flathub:app/org.kde.krita/x86_64/stable"

      # OBS
      "flathub:app/com.obsproject.Studio/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.GStreamerVaapi/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.Gstreamer/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.InputOverlay/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.SceneSwitcher/x86_64/stable"
      "flathub:runtime/com.obsproject.Studio.Plugin.WebSocket/x86_64/stable"

      # Gaming
      "flathub:app/com.usebottles.bottles/x86_64/stable"
      "flathub:app/sh.ppy.osu/x86_64/stable"

      # Vulkan utils
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/23.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/23.08"

      # Utils
      "flathub:runtime/org.gtk.Gtk3theme.Adwaita-dark/x86_64/3.22"
      "flathub:runtime/org.gtk.Gtk3theme.adw-gtk3-dark/x86_64/3.22"
    ];
    overrides = {
      "global" = {
        filesystems = [
          "xdg-config/gtkrc:ro"
          "xdg-config/gtkrc-2.0:ro"
          "xdg-config/gtk-3.0:ro"
          "xdg-config/gtk-4.0:ro"
        ];
      };
      "sh.ppy.osu" = {
        filesystems = [
          "/mnt/wiwi/osu-lazer:rw"
          "/home/reisen/Music:rw"
        ];
      };
      "com.usebottles.bottles" = {
        sockets = [ "pcsc" ];
        filesystems = [
          "xdg-downloads:rw"
          "xdg-pictures:rw"
          "xdg-data/Steam:rw"
          "xdg-config/MangoHud:ro"
          "~/games:rw"
        ];
      };
    };
  };
}
