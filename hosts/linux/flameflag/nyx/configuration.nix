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

    inputs.nixos-hardware-trivial.nixosModules.lenovo-legion-15arh05h
    inputs.sops-nix-trivial.nixosModules.sops
    {
      sops = {
        age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/secrets.yaml;
      };
    }
  ];

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

  # Keyboard layout
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      # Communication Tools
      telegram-desktop
      ;
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
