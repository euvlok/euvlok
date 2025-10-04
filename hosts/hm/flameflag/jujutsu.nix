{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  userName = "DontEatOreo";
  userEmail = "57304299+${userName}@users.noreply.github.com";
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsZFHUhLSPiz0EF1Q59jzu7IS7qdn3MSEImztN4KgmN";
  format = "ssh";
in
{
  home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs.jujutsu.settings = {
    user.email = userEmail;
    user.name = userName;
    git.sign-on-push = true;
    git.push-bookmark-prefix = "flameflag/push-";
    signing = {
      behavior = "drop";
      backend = format;
      inherit key;
      backends.ssh.program =
        if osConfig.nixpkgs.hostPlatform.isLinux then
          (lib.getExe' pkgs._1password-gui "op-ssh-sign")
        else
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
    };
  };
}
