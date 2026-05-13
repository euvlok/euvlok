{ pkgs, config, ... }:
{
  system.primaryUser = "flame";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = "/Users/${config.system.primaryUser}";
    shell = pkgs.unstable.zsh;
  };

  services.tailscale.enable = true;
  services.tailscale.package = pkgs.unstable.tailscale;

  sops = {
    age.keyFile = "/Users/${config.system.primaryUser}/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/flameflag.yaml;
    secrets = {
      github-token = {
        mode = "0440";
        group = "staff";
      };
      github_ssh = {
        uid = 0;
        gid = 0;
        group = "wheel";
        owner = "root";
      };
      raycast-openrouter-api-key = {
        mode = "0644";
        group = "wheel";
        owner = "root";
        uid = 0;
        gid = 0;
      };
      migadu = {
        owner = config.system.primaryUser;
        mode = "0400";
      };
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.github-token.path}
  '';

  system.stateVersion = 6;
}
