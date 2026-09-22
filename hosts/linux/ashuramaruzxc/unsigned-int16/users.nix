{
  pkgs,
  config,
  ...
}:
{
  sops.secrets.ashuramaru.neededForUsers = true;
  users = {
    mutableUsers = false;
    groups = {
      ashuramaru = {
        gid = config.users.users.ashuramaru.uid;
        members = [ "${config.users.users.ashuramaru.name}" ];
      };
    };
    users = {
      root = {
        initialHashedPassword = "";
        openssh.authorizedKeys.keys = config.users.users.ashuramaru.openssh.authorizedKeys.keys;
        shell = pkgs.zsh;
      };
      ashuramaru = {
        isNormalUser = true;
        description = "Mariè Levjéwa";
        home = "/Users/marie";
        uid = 1000;
        hashedPasswordFile = config.sops.secrets.ashuramaru.path;
        extraGroups = [
          "wheel"
          "networkmanager"
          "camera"
          "video"
          "audio"
          "storage"
        ];
        openssh.authorizedKeys.keys = import ../../../keys/ashuramaru.nix;
        shell = pkgs.zsh;
      };
    };
  };
}
