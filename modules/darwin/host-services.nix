{ pkgs, ... }:
{
  environment.system.packages = [ pkgs.tailscale ];
  system.activation.steps.keyboard = {
    deps = [ "run" ];
    text = ''
      /usr/bin/hidutil property --set '{"UserKeyMapping":[]}' >/dev/null
    '';
  };
  launchd.daemons.tailscaled = {
    enable = true;
    config = {
      Label = "com.tailscale.tailscaled";
      ProgramArguments = [ "${pkgs.tailscale}/bin/tailscaled" ];
      RunAtLoad = true;
    };
  };
}
