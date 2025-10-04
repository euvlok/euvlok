_: {
  sops.secrets.foldingathome_passkey = { };
  sops.secrets.foldingathome_token = { };

  services.foldingathome = {
    enable = true;
    user = "Maria";
    team = 2164;
    # extraArgs = [
    #   "--cause alzheimers"
    #   "--open-web-control true"
    #   "--passkey ${builtins.readFile config.sops.secrets.foldingathome_passkey.path}"
    #   "--account-token ${builtins.readFile config.sops.secrets.foldingathome_token.path}"
    # ];
  };
}
