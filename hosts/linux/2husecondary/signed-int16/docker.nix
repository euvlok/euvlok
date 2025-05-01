{
  pkgs,
  lib,
  config,
  ...
}:
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
    extraPackages = builtins.attrValues { inherit (pkgs) gvisor gvproxy tun2socks; };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.oci-containers.backend = "podman";
  hardware.nvidia-container-toolkit = lib.optionalAttrs (config.nixos.nvidia.enable) {
    enable = true;
    mount-nvidia-executables = true;
  };
  environment.systemPackages = [ pkgs.distrobox ];
  users.groups = {
    docker.members = [ "${config.users.users.reisen.name}" ];
    podman.members = [ "${config.users.users.reisen.name}" ];
  };
}
