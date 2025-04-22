{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./fonts.nix
    ./input.nix
    ./power.nix
  ];

  services = {
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    desktopManager.plasma6.enable = true;
  };

  environment.plasma6.excludePackages = builtins.attrValues {
    inherit (pkgs.kdePackages) discover;
    inherit (pkgs) orca;
  };

  users.defaultUserShell = pkgs.zsh;
  programs = {
    nano.enable = true;
    nano.syntaxHighlight = true;
    zsh.enable = true;
    dconf.enable = true;
    steam.enable = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.plugins = builtins.attrValues { inherit (pkgs) networkmanager-openvpn; };
    networkmanager.wifi.powersave = true;
  };

  services.mullvad-vpn.enable = true;
  time.timeZone = "Asia/Ho_Chi_Minh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";

  services.protonmail-bridge = {
    enable = true;
    package =
      # Ensure pass is not in the PATH.
      pkgs.runCommand "protonmail-bridge"
        {
          bridge = pkgs.protonmail-bridge;
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
        ''
          mkdir -p "$out/bin"
          makeWrapper "$bridge/bin/protonmail-bridge" "$out/bin/protonmail-bridge" \
            --set PATH ${lib.strings.makeBinPath [ pkgs.gnome-keyring ]}
        '';
  };

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";

  users.users = {
    nanachi = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "libvirtd"
      ];
    };
  };

  # Virt-manager
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Docker
  virtualisation.docker.rootless.enable = true;
  virtualisation.docker.rootless.setSocketVariable = true;

  services.flatpak.enable = true;
  services.earlyoom.enable = true;

  # Set default editor
  environment.variables = {
    EDITOR = "nvim";
  };

  # https://wiki.nixos.org/wiki/FAQ#When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
