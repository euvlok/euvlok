{ pkgs, config, ... }:
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
        shell = pkgs.zsh;
      };
      ashuramaru = {
        isNormalUser = true;
        description = "Maria Levjewa";
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
        openssh.authorizedKeys.keys = [
          "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNR1p1OviZgAkv5xQ10NTLOusPT8pQUG2qCTpO3AhmxaZM2mWNePVNqPnjxNHjWN+a/FcZ5on74QZQJtwXI5m80AAAAOc3NoOnJlbW90ZS1kc2E= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
          ### --- ecdsa-sk --- ###
          ### --- ecdsa-sk_bio --- ###
          "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBFdzdMIdu/bKlIkGx1tCf1sL65NwrmpvBZQ+nSbKknbGHdrXv33mMzLVUsCGUaUxmeYcCULNNtSb0kvgDjRlcgIAAAAOc3NoOnJlbW90ZS1kc2E= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
          ### --- ecdsa-sk_bio --- ###
          ### --- ed25519-sk --- ###
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKNF4qCh49NCn6DUnzOCJ3ixzLyhPCCcr6jtRfQdprQLAAAACnNzaDpyZW1vdGU= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
          ### --- ed25519-sk --- ###
          ### --- ed25519-sk_bio --- ###
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEF0v+eyeOEcrLwo3loXYt9JHeAEWt1oC2AHh+bZP9b0AAAACnNzaDpyZW1vdGU= email:ashuramaru@tenjin-dk.com id:ashuramaru@unsigned-int32"
          ### --- ed25519-sk_bio --- ###
        ];
        shell = pkgs.zsh;
      };
    };
  };
}
