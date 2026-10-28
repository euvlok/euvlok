{
  config,
  lib,
  pkgs,
  _class,
  ...
}:
let
  isLinux = _class == "nixos";
  cfg = if isLinux then config.security.pki else { };
  caBundle = "/etc/ssl/certs/ca-certificates.crt";
  publicCAs = pkgs.cacert.override {
    blacklist = cfg.caCertificateBlacklist or [ ];
    extraCertificateFiles = cfg.certificateFiles or [ ];
    extraCertificateStrings = cfg.certificates or [ ];
  };
  bundleName =
    if cfg ? useCompatibleBundle && cfg.useCompatibleBundle then
      "ca-no-trust-rules-bundle.crt"
    else
      "ca-bundle.crt";
  # Reuse NixOS's public trust policy without putting the private CA in the store
  publicBundle = cfg.caBundle or "${publicCAs}/etc/ssl/certs/${bundleName}";
in
{
  config = lib.modules.mkMerge [
    {
      # SOPS owns the final bundle; the private CA never enters a store derivation.
      sops.secrets.tenjin_ca = {
        sopsFile = ../../secrets/tenjin-ca.yaml;
        mode = "0444";
      };
      sops.templates."tenjin-ca-bundle.crt" = {
        path = caBundle;
        mode = "0444";
        file = pkgs.runCommand "tenjin-ca-bundle-template.crt" { } ''
          cat ${publicBundle} > "$out"
          printf '\n%s\n' ${lib.escapeShellArg config.sops.placeholder.tenjin_ca} >> "$out"
        '';
      };
      environment.variables = {
        SSL_CERT_FILE = lib.mkDefault caBundle;
        NIX_SSL_CERT_FILE = lib.mkDefault caBundle;
      };
    }
    (lib.attrsets.optionalAttrs isLinux {
      security.pki.installCACerts = false;
      environment.etc = {
        "ssl/certs/ca-bundle.crt".source = caBundle;
        "pki/tls/certs/ca-bundle.crt".source = caBundle;
        "ssl/trust-source".source = pkgs.runCommand "tenjin-trust-source" { } ''
          mkdir -p "$out/anchors"
          ln -s ${publicCAs.p11kit}/etc/ssl/trust-source/* "$out/"
          ln -s ${lib.escapeShellArg config.sops.secrets.tenjin_ca.path} "$out/anchors/tenjin-ca.pem"
        '';
      };
    })
  ];
}
