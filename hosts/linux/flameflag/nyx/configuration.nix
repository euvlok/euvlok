{
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./programs.nix
    ./services.nix
    ./fonts.nix
    ./systemd.nix
    ./kanata.nix

    inputs.sops-nix-trivial.nixosModules.sops
    {
      sops = {
        age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/secrets.yaml;
      };
    }
  ];

  hardware.nvidia.prime = {
    reverseSync.enable = true;
    amdgpuBusId = "PCI:6:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Users
  sops.secrets.nyx-password.neededForUsers = true;
  users.mutableUsers = false;
  users.users.nyx = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "network"
      "networkmanager"
      "audio"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.nyx-password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMG8yRBKWpJT8cqgMLtIag4M0VrOXLvhM9kqiEIwTpxj (none)"
    ];
  };

  nixos.locale = {
    enable = true;
    timeZone = "Europe/Sofia";
  };

  nixos.boot.systemd-boot.enable = true;

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs) telegram-desktop;
    inherit (pkgs.eupkgs) claude-code opencode;
  };

  services.pipewire.wireplumber.extraConfig = {
    # Fixes the "Corsair HS80 Wireless" Volume desync between Headset & System
    "volume-sync" = {
      "bluez5.enable-absolute-volume" = true;
    };
  };

  # https://wiki.nixos.org/wiki/FAQ#When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
