{ pkgs, ... }:
{
  # Enroll the key as your normal user with:
  # pamu2fcfg --pin-verification --no-user-presence
  # Store its output in ~/.config/Yubico/u2f_keys.
  environment.systemPackages = [ pkgs.pam_u2f ];

  security = {
    polkit.adminIdentities = [ "unix-group:wheel" ];
    pam = {
      u2f = {
        # A successful key authentication replaces the account password.
        # Missing keys and failed attempts fall through to pam_unix.
        control = "sufficient";
        settings = {
          pinverification = 1;
          userpresence = 0;
          userverification = 0;
        };
      };
      services = {
        login = {
          sshAgentAuth = true;
          u2f.enable = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
        };
        su = {
          sshAgentAuth = true;
          u2f.enable = true;
        };
        sudo = {
          sshAgentAuth = true;
          u2f.enable = true;
        };
        sudo-i.u2f.enable = true;
        kde.u2f.enable = true;
        polkit-1.u2f.enable = true;
        sshd = {
          sshAgentAuth = true;
          u2f.enable = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
          googleAuthenticator.enable = true;
        };
      };
    };
  };

  # NixOS only adds these helper permissions automatically when U2F is
  # enabled globally; we enable it for selected PAM services instead.
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = [
      "/dev/urandom r"
      "char-hidraw rw"
    ];
    ProtectHome = "read-only";
  };
}
