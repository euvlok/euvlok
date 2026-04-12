{ pkgs, config, ... }:
{
  system.primaryUser = "flame";

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs.eupkgs) claude-code opencode;
  };

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = "/Users/${config.system.primaryUser}";
    shell = pkgs.zsh;
  };

  system.stateVersion = 6;
}
