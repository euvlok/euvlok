{
  lib,
  pkgs,
  config,
  ...
}:
let
  systemRunnerLink = "/Users/${config.system.primaryUser}/.local/bin/system-runner";
  systemRunnerTarget = "/Users/${config.system.primaryUser}/.local/opt/system-run-mcp/latest/bin/system-runner";
  tailscaleExe = lib.meta.getExe config.services.tailscale.package;
in
{
  system.primaryUser = "flame";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  security.sudo.extraConfig = ''
    Cmnd_Alias SYSTEM_RUNNER = ${systemRunnerLink}, ${systemRunnerTarget}
    ${config.system.primaryUser} ALL=(ALL) NOPASSWD: SYSTEM_RUNNER
  '';

  users.users.${config.system.primaryUser} = {
    name = config.system.primaryUser;
    home = "/Users/${config.system.primaryUser}";
    shell = pkgs.unstable.zsh;
  };

  services.tailscale.enable = true;
  services.tailscale.package = pkgs.unstable.tailscale;

  launchd.daemons.tailscale-ssh = {
    script = ''
      i=0
      while [ "$i" -lt 30 ]; do
        if ${tailscaleExe} set --ssh=true; then
          exit 0
        fi
        i=$((i + 1))
        sleep 2
      done
      exit 1
    '';
    serviceConfig = {
      Label = "com.tailscale.tailscale-ssh";
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ThrottleInterval = 30;
      ProcessType = "Background";
      StandardOutPath = "/var/log/tailscale-ssh.log";
      StandardErrorPath = "/var/log/tailscale-ssh.log";
    };
  };

  sops = {
    age.keyFile = "/Users/${config.system.primaryUser}/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../../../../secrets/flameflag.yaml;
    secrets = {
      github-token = {
        mode = "0440";
        group = "staff";
      };
      github_ssh = {
        uid = 0;
        gid = 0;
        group = "wheel";
        owner = "root";
      };
      raycast-openrouter-api-key = {
        mode = "0644";
        group = "wheel";
        owner = "root";
        uid = 0;
        gid = 0;
      };
      migadu = {
        owner = config.system.primaryUser;
        mode = "0400";
      };
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.github-token.path}
  '';

  system.stateVersion = 6;
}
