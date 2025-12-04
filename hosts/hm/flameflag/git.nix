{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  userName = "FlameFlag";
  userEmail = "57304299+${userName}@users.noreply.github.com";
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsZFHUhLSPiz0EF1Q59jzu7IS7qdn3MSEImztN4KgmN";
  format = "ssh";
in
{
  home.file.".ssh/allowed_signers".text = ''
    ${userEmail} ${key}
  '';

  programs = {
    gitui.enable = true;
    gh.enable = true;
    gh.settings.git_protocol = format;
    git = {
      settings = {
        user = {
          name = userName;
          email = userEmail;
        };
      };
      signing = {
        inherit key format;
        signByDefault = true;
        signer =
          if pkgs.stdenvNoCC.isLinux then
            (lib.getExe' pkgs._1password-gui "op-ssh-sign")
          else
            "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };
  };
}
