_: {
  # sops.secrets.gh_token = {
  #   mode = "0440";
  #   group = "users";
  # };
  # sops.secrets.netrc_creds = {
  #   mode = "0440";
  #   group = "users";
  # };

  # nix.extraOptions = ''
  #   !include ${config.sops.secrets.gh_token.path}
  # '';
  # environment.etc."determinate/config.json".text = lib.strings.toJSON {
  #   authentication.additionalNetrcSources = [ config.sops.secrets.netrc_creds.path ];
  # };

  # Determinate Nixd owns automatic garbage collection. Keeping a second
  # nix-gc timer would race its free-space-aware collector.
}
