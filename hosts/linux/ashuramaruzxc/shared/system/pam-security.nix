_: {
  security = {
    polkit.adminIdentities = [ "unix-group:wheel" ];
    pam = {
      services = {
        login = {
          sshAgentAuth = true;
          u2fAuth = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
        };
        su = {
          sshAgentAuth = true;
          u2fAuth = true;
        };
        sudo = {
          sshAgentAuth = true;
          u2fAuth = true;
        };
        sshd = {
          sshAgentAuth = true;
          u2fAuth = true;
          enableGnomeKeyring = true;
          enableKwallet = true;
          googleOsLoginAuthentication = true;
          googleOsLoginAccountVerification = true;
          googleAuthenticator.enable = true;
        };
      };
    };
  };
}
