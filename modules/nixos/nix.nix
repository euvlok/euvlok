{ inputs, ... }:
{
  imports = [ inputs.determinate.nixosModules.default ];
  systemd.services.nix-daemon.serviceConfig = {
    CPUQuota = "90%";
    MemoryHigh = "70%";
    MemoryMax = "85%";
    MemorySwapMax = "50%";
  };
}
