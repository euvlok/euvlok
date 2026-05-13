{
  pkgs,
  ...
}:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.tailscale;
  };

  programs.mtr.enable = true;

  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
}
