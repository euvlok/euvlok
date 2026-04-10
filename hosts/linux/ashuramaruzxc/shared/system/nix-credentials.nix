{ config, ... }:
{
  sops.secrets.gh_token = {
    mode = "0440";
    group = "users";
  };
  sops.secrets.netrc_creds = {
    mode = "0440";
    group = "users";
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.gh_token.path}
  '';
  nix.settings.netrc-file = config.sops.secrets.netrc_creds.path;

  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";
}
