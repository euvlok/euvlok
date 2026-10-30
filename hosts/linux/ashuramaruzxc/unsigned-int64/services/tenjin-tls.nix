{ pkgs, ... }:
{
  systemd.services.tenjin-tls-renewal = {
    description = "Renew Tenjin cert";
    after = [ "nginx.service" ];
    requisite = [ "nginx.service" ];
    path = [
      pkgs.openssl
      pkgs.coreutils
      pkgs.curl
      pkgs.systemd
    ];
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
      export_file=/root/tenjin.com-certificate.pem
      stage=$(mktemp -d "$RUNTIME_DIRECTORY/renew.XXXXXXXX")
      backup=
      installed=false

      cleanup() {
        status=$?
        trap - EXIT
        if (( status != 0 )) && "$installed"; then
          cp -p "$backup/tenjin.com.key" "$cert_dir/tenjin.com.key"
          cp -p "$backup/tenjin.com.csr" "$cert_dir/tenjin.com.csr"
          cp -p "$backup/tenjin.com.crt" "$cert_dir/tenjin.com.crt"
          if [[ -f "$backup/export.pem" ]]; then
            cp -p "$backup/export.pem" "$export_file"
          else
            rm -f "$export_file"
          fi
          if ! systemctl reload nginx.service; then
            printf 'Failed to reload nginx after restoring certificates\n' >&2
          fi
          printf 'Renewal failed; restored certificates from %s\n' "$backup" >&2
        fi
        rm -rf "$stage"
        exit "$status"
      }
      trap cleanup EXIT

      # Preserve the existing CA and names while rotating the server key.
      openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 \
        -out "$stage/tenjin.com.key"
      openssl x509 -x509toreq -in "$cert_dir/tenjin.com.crt" \
        -key "$stage/tenjin.com.key" -sha384 \
        -copy_extensions copy -ext subjectAltName \
        -out "$stage/tenjin.com.csr"
      cat > "$stage/server.cnf" <<'EXTENSIONS'
      [server]
      basicConstraints = critical,CA:FALSE
      keyUsage = critical,digitalSignature
      extendedKeyUsage = serverAuth
      EXTENSIONS
      openssl x509 -req -in "$stage/tenjin.com.csr" \
        -CA "$cert_dir/ca.crt" -CAkey "$cert_dir/ca.key" \
        -sha384 -days 365 -set_serial "0x$(openssl rand -hex 19)" \
        -copy_extensions copy -extfile "$stage/server.cnf" -extensions server \
        -out "$stage/tenjin.com.crt"

      openssl verify -check_ss_sig -CAfile "$cert_dir/ca.crt" "$cert_dir/ca.crt"
      openssl verify -CAfile "$cert_dir/ca.crt" -purpose sslserver \
        -verify_hostname metrics.tenjin.com "$stage/tenjin.com.crt"
      cert_pubkey=$(openssl x509 -in "$stage/tenjin.com.crt" -pubkey -noout)
      key_pubkey=$(openssl pkey -in "$stage/tenjin.com.key" -pubout)
      [[ "$cert_pubkey" == "$key_pubkey" ]]

      mkdir -p "$STATE_DIRECTORY/backups"
      backup=$(mktemp -d "$STATE_DIRECTORY/backups/renew.XXXXXXXX")
      cp -p "$cert_dir/tenjin.com.key" "$backup/tenjin.com.key"
      cp -p "$cert_dir/tenjin.com.csr" "$backup/tenjin.com.csr"
      cp -p "$cert_dir/tenjin.com.crt" "$backup/tenjin.com.crt"
      if [[ -f "$export_file" ]]; then
        cp -p "$export_file" "$backup/export.pem"
      fi
      installed=true
      install -o nginx -g nginx -m 0640 "$stage/tenjin.com.key" "$cert_dir/tenjin.com.key"
      install -o nginx -g nginx -m 0640 "$stage/tenjin.com.csr" "$cert_dir/tenjin.com.csr"
      install -o nginx -g nginx -m 0640 "$stage/tenjin.com.crt" "$cert_dir/tenjin.com.crt"
      cat "$stage/tenjin.com.crt" "$cert_dir/ca.crt" > "$export_file"
      chmod 0644 "$export_file"

      systemctl reload nginx.service
      curl --cacert "$cert_dir/ca.crt" \
        --resolve metrics.tenjin.com:443:127.0.0.1 \
        --fail --silent --show-error --max-time 20 \
        https://metrics.tenjin.com/prometheus/-/ready
      printf '\nBackup: %s\n' "$backup"
      openssl x509 -in "$cert_dir/ca.crt" -noout -dates -fingerprint -sha256
      openssl x509 -in "$cert_dir/tenjin.com.crt" -noout -dates -fingerprint -sha256
    '';
  };
}
