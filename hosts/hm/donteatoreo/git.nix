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
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
  home.file.".ssh/allowed_signers".text = ''
    ${userEmail} ${key}
  '';

  home.packages = builtins.attrValues { inherit (pkgs) watchman; };

  programs = {
    gitui.enable = true;
    gh.enable = true;
    gh.settings.git_protocol = format;
    git = {
      inherit userName userEmail;
      signing = {
        inherit key format;
        signByDefault = true;
        signer =
          if osConfig.nixpkgs.hostPlatform.isLinux then
            (lib.getExe' pkgs._1password-gui "op-ssh-sign")
          else
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };
    jujutsu = {
      settings = {
        user.email = userEmail;
        user.name = userName;
        git.sign-on-push = true;
        git.push-bookmark-prefix = "donteatoreo/push-";
        signing = {
          behavior = "drop";
          backend = "ssh";
          inherit key;
          backends.ssh.program =
            if osConfig.nixpkgs.hostPlatform.isLinux then
              (lib.getExe' pkgs._1password-gui "op-ssh-sign")
            else
              "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
        };
      };
    };
  };
}
