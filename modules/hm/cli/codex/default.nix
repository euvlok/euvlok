{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.euvlok.home.codex;
in
{
  options.euvlok.home.codex = {
    enable = lib.options.mkEnableOption "Codex";
    omp.enable = lib.options.mkEnableOption "Oh My Pi alongside Codex";
    opencode.enable = lib.options.mkEnableOption "OpenCode alongside Codex";
  };

  config = lib.modules.mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.mcp-nixos
    ]
    ++ lib.lists.optional cfg.omp.enable pkgs.unstable.omp
    ++ lib.lists.optional cfg.opencode.enable pkgs.unstable.opencode;

    programs.codex = {
      enable = true;
      package = pkgs.eupkgs.codex;
      settings.mcp_servers = {
        nixos = {
          command = lib.meta.getExe pkgs.unstable.mcp-nixos;
          enabled = lib.modules.mkDefault true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 120;
          default_tools_approval_mode = "auto";
        };

        openaiDeveloperDocs = {
          url = "https://developers.openai.com/mcp";
          enabled = lib.modules.mkDefault true;
          startup_timeout_sec = 20;
          tool_timeout_sec = 60;
          default_tools_approval_mode = "auto";
        };
      };
    };
  };
}
