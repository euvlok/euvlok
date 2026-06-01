{
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./programs.nix
    ./services.nix
    ./sound.nix
    ./fonts.nix
    ./systemd.nix
    ./kanata.nix
    ./users.nix

    {
      sops = {
        age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
        defaultSopsFile = ../../../../secrets/flameflag.yaml;
        secrets = {
          github-token = {
            mode = "0440";
            group = "users";
          };
          github_ssh = {
            uid = 0;
            gid = 0;
          };
          migadu = {
            owner = "nyx";
            mode = "0400";
          };
        };
      };
    }
  ];

  hardware.nvidia.prime = {
    reverseSync.enable = true;
    amdgpuBusId = "PCI:6:0:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.github-token.path}
  '';

  nixos.locale = {
    enable = true;
    timeZone = "Europe/Sofia";
  };

  nixos.boot.systemd-boot.enable = true;

  # https://wiki.nixos.org/wiki/FAQ#When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
