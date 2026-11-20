{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.security.pki;
  caBundle = "/etc/ssl/certs/ca-certificates.crt";
  publicCAs = pkgs.cacert.override {
    blacklist = cfg.caCertificateBlacklist;
    extraCertificateFiles = cfg.certificateFiles;
    extraCertificateStrings = cfg.certificates;
  };
  bundleName =
    if cfg ? useCompatibleBundle && cfg.useCompatibleBundle then
      "ca-no-trust-rules-bundle.crt"
    else
      "ca-bundle.crt";
in
{
  # SOPS owns the final bundle, keeping the private CA out of the store
  security.pki.installCACerts = false;
  sops.secrets.tenjin_ca = {
    sopsFile = ../../secrets/tenjin-ca.yaml;
    mode = "0444";
  };
  sops.templates."tenjin-ca-bundle.crt" = {
    path = caBundle;
    mode = "0444";
    file = pkgs.runCommand "tenjin-ca-bundle-template.crt" { } ''
      cat ${publicCAs}/etc/ssl/certs/${bundleName} > "$out"
      printf '\n%s\n' ${lib.strings.escapeShellArg config.sops.placeholder.tenjin_ca} >> "$out"
    '';
  };
  environment.variables = {
    SSL_CERT_FILE = lib.modules.mkDefault caBundle;
    NIX_SSL_CERT_FILE = lib.modules.mkDefault caBundle;
  };
  environment.etc = lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    "ssl/certs/ca-bundle.crt".source = caBundle;
    "pki/tls/certs/ca-bundle.crt".source = caBundle;
    "ssl/trust-source".source = pkgs.linkFarm "tenjin-trust-source" {
      "ca-bundle.trust.p11-kit" = "${publicCAs.p11kit}/etc/ssl/trust-source/ca-bundle.trust.p11-kit";
      # This link points to the runtime secret, not to certificate contents in the store
      "anchors/tenjin-ca.pem" = config.sops.secrets.tenjin_ca.path;
    };
  };
}
