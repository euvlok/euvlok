{ inputs, ... }:
{
  unsigned-int8 = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../shared/system.nix
      ./brew.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
      {
        nixpkgs.hostPlatform.system = "aarch64-darwin";
        security.pam.services.sudo_local.touchIdAuth = true;
        networking = {
          computerName = "Marie's Mac Mini M2 Pro unsigned-int8";
          hostName = "unsigned-int8";
          localHostName = "unsigned-int8";
          knownNetworkServices = [
            "Ethernet"
            "Thunderbolt Bridge"
            "Wi-Fi"
          ];
          dns = [
            "192.168.1.1"
            "172.16.31.1"
            "fd17:216b:31bc:1::1"
          ];
        };

        users.users = {
          ashuramaru = {
            home = "/Users/ashuramaru";
            shell = inputs.nixpkgs-donteatoreo.legacyPackages.aarch64-darwin.zsh;
          };
          meanrin = {
            home = "/Users/meanrin";
            shell = inputs.nixpkgs-donteatoreo.legacyPackages.aarch64-darwin.zsh;
          };
        };

        programs = {
          gnupg.agent.enable = true;
          gnupg.agent.enableSSHSupport = true;
          nix-index.enable = true;
        };

        # Environment
        environment.systemPackages = builtins.attrValues {
          inherit (inputs.nixpkgs-donteatoreo.legacyPackages.aarch64-darwin)
            # Literally should be bultin but apple being apple
            soundsource
            # Utils
            wireguard-tools
            smartmontools

            # Virtualization
            vfkit
            podman
            podman-compose

            # Android
            android-tools
            scrcpy
            ;
        };
      }
    ];
  };
}
