{ pkgs, config, ... }:
{
  system.primaryUser = "flame";

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs) claude-code;
    inherit (pkgs.unstable) opencode;
  };

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = "/Users/${config.system.primaryUser}";
    shell = pkgs.zsh;
  };

  system.stateVersion = 6;
}
