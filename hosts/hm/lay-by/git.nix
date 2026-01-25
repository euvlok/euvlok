{
  pkgs,
  lib,
  config,
  ...
}:
let
  email = "44959695+lay-by@users.noreply.github.com";
  name = "lay-by";
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJtuZLShJatHlAl+dVtjacu9lrngPtBgzh62H34WPB34 bean_s@riseup.net";
  format = "ssh";
in
{
  programs.gh.settings.git_protocol = format;
  programs.git.settings = {
    user = { inherit email name; };
    credential.helper = "libsecret";
  };
  programs.jujutsu.settings = {
    user = { inherit email name; };
    git = {
      sign-on-push = true;
      push-bookmark-prefix = "lay-by/push-";
    };
    signing = {
      behavior = "own";
      backend = "ssh";
      inherit key;
      backends.ssh.program = lib.getExe' pkgs.openssh_hpn "ssh-keygen";
      backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
    };
  };
}
