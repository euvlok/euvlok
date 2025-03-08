{ pkgs, config, ... }:
{
  users = {
    mutableUsers = false;
    groups = {
      ashuramaru = {
        gid = config.users.users.ashuramaru.uid;
        members = [ "ashuramaru" ];
      };
      meanrin = {
        gid = config.users.users.meanrin.uid;
        members = [ "meanrin" ];
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
        initialHashedPassword = "$6$79Eopfg.bX9kzgyR$mPzq3.dFGkCaX2NiAPiTqltBQ0b9gLpEPsX7YdKLyuMbvLssUlfFDiOhZ.FZ.AwS6JbXQ6AXB41Yq5QpJxWJ6/";
        hashedPassword = "$6$77kLLDvOgu.dYPBM$r5c3DxYM9fYb0qUqvJ8TwDbjFtGol3fIAj38U4785h9iXkzNMiDrr71xigw2JE/uOzWsa5LfvhtsR4r30/fmo/";
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
      meanrin = {
        isNormalUser = true;
        description = "Alex";
        home = "/Users/alex";
        uid = 1001;
        initialHashedPassword = "$6$Vyk8fqJUAWcfHcZ.$JrE0aK4.LSzpDlXNIHs9LFHyoaMXHFe9S0B66Kx8Wv0nVCnh7ACeeiTIkX95YjGoH0R8DavzSS/aSizJH1YgV0";
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "storage"
        ];
        openssh.authorizedKeys.keys = [
          "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBCzoNOzhhF9uYDu7CbuzVRJ2K6dClXLrEoJrQvIYjnxHTBMqKuByi9M2HEmkpGO+a3H3WjeeXfqjH2CwZJ97jmIAAAAEc3NoOg== meanrin@outlook.com"
        ];
      };
    };
  };
}
