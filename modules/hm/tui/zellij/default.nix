{ lib, config, ... }:
let
  cfg = config.euvlok.home.zellij;
in
{
  imports = [ ./settings.nix ];

  options.euvlok.home.zellij = {
    enable = lib.options.mkEnableOption "Zellij";

    autoStart = lib.options.mkEnableOption "Zellij on interactive shell startup" // {
      description = ''
        Whether to start Zellij automatically in Bash, Fish, and Zsh.
        The shells must be enabled separately. The shared nix-darwin Zsh
        module also supports this option for the primary user.

        Individual shells can be excluded with
        {option}`programs.zellij.enableBashIntegration`,
        {option}`programs.zellij.enableFishIntegration`, and
        {option}`programs.zellij.enableZshIntegration`.
      '';
    };
  };

  config = lib.modules.mkIf cfg.enable {
    programs.zellij = {
      enable = true;

      enableBashIntegration = lib.modules.mkDefault cfg.autoStart;
      enableFishIntegration = lib.modules.mkDefault cfg.autoStart;
      enableZshIntegration = lib.modules.mkDefault cfg.autoStart;
      attachExistingSession = lib.modules.mkDefault cfg.autoStart;
      exitShellOnExit = lib.modules.mkDefault false;
    };
  };
}
