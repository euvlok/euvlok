{
  config,
  lib,
  ...
}:
let
  cfg = config.services.foldingathome;
  args = [
    "--team"
    (toString cfg.team)
  ]
  ++ lib.optionals (cfg.user != null) [
    "--user"
    cfg.user
  ]
  ++ cfg.extraArgs;
in
{
  sops.secrets.foldingathome_passkey = { };
  sops.secrets.foldingathome_token = { };

  sops.templates."foldingathome.env".content = ''
    FOLDINGATHOME_PASSKEY=${config.sops.placeholder.foldingathome_passkey}
    FOLDINGATHOME_TOKEN=${config.sops.placeholder.foldingathome_token}
  '';

  services.foldingathome = {
    enable = true;
    user = "Maria";
    team = 2164;
    extraArgs = [
      "--cause"
      "alzheimers"
      "--open-web-control"
    ];
  };

  systemd.services.foldingathome = {
    serviceConfig.EnvironmentFile = config.sops.templates."foldingathome.env".path;
    script = lib.mkForce ''
      exec ${lib.getExe cfg.package} ${lib.escapeShellArgs args} \
        --passkey "$FOLDINGATHOME_PASSKEY" \
        --account-token "$FOLDINGATHOME_TOKEN"
    '';
  };
}
