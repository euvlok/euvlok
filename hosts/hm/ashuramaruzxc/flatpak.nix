{ inputs, ... }:
{
  imports = [ inputs.flatpak-declerative.homeModule ];

  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
      "moe-launcher" = "https://gol.launcher.moe/gol.launcher.moe.flatpakrepo";
    };
    packages = [
      # Desktop
      "flathub:app/com.github.tchx84.Flatseal/x86_64/stable" # Easier permission manager
      "flathub:app/com.usebottles.bottles/x86_64/stable"

      # `
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.vkBasalt/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08"
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
      "com.usebottles.bottles" = {
        sockets = [ "pcsc" ];
        filesystems = [
          "xdg-downloads:rw"
          "xdg-pictures:rw"
          "xdg-data/Steam:rw"
          "xdg-data/games:rw"
          "xdg-config/MangoHud:ro"
        ];
      };
    };
  };
}
