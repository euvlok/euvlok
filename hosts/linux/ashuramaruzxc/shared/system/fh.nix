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
  ++ lib.lists.optionals (cfg.user != null) [
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
    script = lib.modules.mkForce ''
      exec ${lib.meta.getExe cfg.package} ${lib.strings.escapeShellArgs args} \
        --passkey "$FOLDINGATHOME_PASSKEY" \
        --account-token "$FOLDINGATHOME_TOKEN"
    '';
  };
}
