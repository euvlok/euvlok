{ config, pkgs, ... }:
{
  systemd.services.tenjin-tls-renewal = {
    description = "Renew Tenjin TLS certificates for five years";
    after = [ "nginx.service" ];
    requisite = [ "nginx.service" ];
    path = [
      pkgs.openssl
      pkgs.coreutils
      pkgs.curl
      pkgs.systemd
      pkgs.sops
      pkgs.jq
    ];
    environment.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      StateDirectory = "tenjin-tls-renewal";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "tenjin-tls-renewal";
      RuntimeDirectoryMode = "0700";
    };
    script = ''
      set -euo pipefail
      cert_dir=/etc/ssl/self/tenjin.com
      ca_dir=/etc/ssl/self
      export_file=/root/tenjin.com-certificate.pem
      start=$(date -u +%Y%m%d%H%M%SZ)
      expiry=$(date -u -d '+5 years' +%Y%m%d%H%M%SZ)
      stage=$(mktemp -d "$RUNTIME_DIRECTORY/renew.XXXXXXXX")
      backup=
      installed=false

      cleanup() {
        status=$?
        trap - EXIT
        if (( status != 0 )) && "$installed"; then
          cp -p "$backup/ca.crt" "$ca_dir/ca.crt"
          cp -p "$backup/domain-ca.crt" "$cert_dir/ca.crt"
          cp -p "$backup/tenjin.com.crt" "$cert_dir/tenjin.com.crt"
          if [[ -f "$backup/export.pem" ]]; then
            cp -p "$backup/export.pem" "$export_file"
          else
            rm -f "$export_file"
          fi
          systemctl reload nginx.service || true
          systemctl try-restart grafana.service || true
          printf 'Renewal failed; restored certificates from %s\n' "$backup" >&2
        fi
        rm -rf "$stage"
        exit "$status"
      }
      trap cleanup EXIT

      # Keep the CA key and subject compatible with the deployed trust anchor.
      openssl x509 -in "$cert_dir/ca.crt" -signkey "$cert_dir/ca.key" \
        -sha256 -not_before "$start" -not_after "$expiry" \
        -set_serial "0x$(openssl rand -hex 19)" -out "$stage/ca.crt"
      openssl x509 -req -in "$cert_dir/tenjin.com.csr" \
        -CA "$stage/ca.crt" -CAkey "$cert_dir/ca.key" \
        -sha256 -not_before "$start" -not_after "$expiry" \
        -set_serial "0x$(openssl rand -hex 19)" \
        -extfile "$cert_dir/openssl.cnf" -extensions v3_req \
        -out "$stage/tenjin.com.crt"

      openssl verify -check_ss_sig -CAfile "$stage/ca.crt" "$stage/ca.crt"
      openssl verify -CAfile "$stage/ca.crt" -purpose sslserver \
        -verify_hostname metrics.tenjin.com "$stage/tenjin.com.crt"
      cert_pubkey=$(openssl x509 -in "$stage/tenjin.com.crt" -pubkey -noout)
      key_pubkey=$(openssl pkey -in "$cert_dir/tenjin.com.key" -pubout)
      [[ "$cert_pubkey" == "$key_pubkey" ]]

      # Preserve the SOPS recipients and encrypt before changing live certificates.
      cp ${config.sops.secrets.tenjin_ca.sopsFile} "$stage/tenjin-ca.yaml"
      chmod 0600 "$stage/tenjin-ca.yaml"
      jq -Rs . < "$stage/ca.crt" \
        | sops set --value-stdin "$stage/tenjin-ca.yaml" '["tenjin_ca"]'

      mkdir -p "$STATE_DIRECTORY/backups"
      backup=$(mktemp -d "$STATE_DIRECTORY/backups/renew.XXXXXXXX")
      cp -p "$ca_dir/ca.crt" "$backup/ca.crt"
      cp -p "$cert_dir/ca.crt" "$backup/domain-ca.crt"
      cp -p "$cert_dir/tenjin.com.crt" "$backup/tenjin.com.crt"
      if [[ -f "$export_file" ]]; then
        cp -p "$export_file" "$backup/export.pem"
      fi
      installed=true
      install -o nginx -g nginx -m 0640 "$stage/ca.crt" "$ca_dir/ca.crt"
      install -o nginx -g nginx -m 0640 "$stage/ca.crt" "$cert_dir/ca.crt"
      install -o nginx -g nginx -m 0640 "$stage/tenjin.com.crt" "$cert_dir/tenjin.com.crt"
      cat "$stage/tenjin.com.crt" "$stage/ca.crt" > "$export_file"
      chmod 0644 "$export_file"

      systemctl reload nginx.service
      systemctl try-restart grafana.service
      curl --cacert "$cert_dir/ca.crt" \
        --resolve metrics.tenjin.com:443:127.0.0.1 \
        --fail --silent --show-error --max-time 20 \
        https://metrics.tenjin.com/prometheus/-/ready
      install -m 0600 "$stage/tenjin-ca.yaml" "$STATE_DIRECTORY/tenjin-ca.yaml"
      printf '\nBackup: %s\n' "$backup"
      printf 'Copy %s/tenjin-ca.yaml to the repository secrets/tenjin-ca.yaml, then rebuild the hosts.\n' "$STATE_DIRECTORY"
      openssl x509 -in "$cert_dir/ca.crt" -noout -dates -fingerprint -sha256
      openssl x509 -in "$cert_dir/tenjin.com.crt" -noout -dates -fingerprint -sha256
    '';
  };
}
