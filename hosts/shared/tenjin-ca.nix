{
  config,
  lib,
  pkgs,
  _class,
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
  # Reuse NixOS's final public trust policy; nix-darwin exposes no bundle option
  publicBundle = cfg.caBundle or "${publicCAs}/etc/ssl/certs/${bundleName}";
in
{
  # SOPS owns the final bundle; the private CA never enters a store derivation.
  security.pki.installCACerts = false;
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
  environment.etc = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    "ssl/certs/ca-bundle.crt".source = caBundle;
    "pki/tls/certs/ca-bundle.crt".source = caBundle;
    "ssl/trust-source".source = pkgs.runCommand "tenjin-trust-source" { } ''
      mkdir -p "$out/anchors"
      ln -s ${publicCAs.p11kit}/etc/ssl/trust-source/* "$out/"
      ln -s ${lib.escapeShellArg config.sops.secrets.tenjin_ca.path} "$out/anchors/tenjin-ca.pem"
    '';
  };
}
// lib.attrsets.optionalAttrs (_class == "darwin") {
  # Run after sops-nix's mkAfter hook has decrypted the certificate
  system.activationScripts.postActivation.text = lib.modules.mkOrder 1600 ''
    /usr/bin/security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain \
      ${lib.escapeShellArg config.sops.secrets.tenjin_ca.path}
  '';
}
