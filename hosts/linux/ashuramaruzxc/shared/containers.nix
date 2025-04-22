{
  pkgs,
  config,
  lib,
  ...
}:
let
  admins = [
    "ashuramaru"
  ];
in
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.podman = {
    enable = true;
    extraPackages = builtins.attrValues { inherit (pkgs) gvproxy gvisor tun2socks; };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };
  virtualisation.oci-containers.backend = "podman";
  hardware.nvidia-container-toolkit = lib.optionalAttrs (config.nixos.nvidia.enable) {
    enable = true;
    mount-nvidia-executables = true;
  };

  systemd.timers."podman-auto-update".wantedBy = [ "timers.target" ];
  environment.systemPackages = [ pkgs.distrobox ];
  users.groups = {
    docker.members = admins;
    podman.members = admins;
  };
}
