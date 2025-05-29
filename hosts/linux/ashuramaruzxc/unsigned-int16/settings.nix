_: {
  networking = {
    hostName = "unsigned-int16";
    hostId = "8425e349";
    interfaces = {
      "end0" = {
        name = "end0";
        useDHCP = true;
        wakeOnLan = {
          enable = true;
          policy = [ "magic" ];
        };
      };
    };
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "end0";
      internalInterfaces = [
        "ve-+"
        "virbr0"
      ];
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        # HTTP
        80
        # HTTPS
        443
        # Proxy
        1080
        3128
      ];
    };
  };
  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      openFirewall = true;
      settings = {
        UseDns = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = true;
        PermitRootLogin = "prohibit-password";
      };
      listenAddresses = [
        {
          addr = "0.0.0.0";
          port = 22;
        }
        {
          addr = "[::]";
          port = 22;
        }
      ];
    };
    vnstat.enable = true;
  };
}
