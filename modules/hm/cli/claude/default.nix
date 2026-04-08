{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.hm.claude-code.enable = lib.mkEnableOption "claude-code";

  config = lib.mkIf config.hm.claude-code.enable {
    home.file.".claude/statusline-command.sh" = {
      source = ./statusline-command.sh;
      executable = true;
    };

    home.file.".claude/settings.json".text = builtins.toJSON {
      statusLine = {
        type = "command";
        command = "${lib.getExe' pkgs.bash "bash"} ~/.claude/statusline-command.sh";
      };
      enabledPlugins = {
        "frontend-design@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "clangd-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "swift-lsp@claude-plugins-official" = true;
      };
      extraKnownMarketplaces = {
        "claude-plugins-official" = {
          source = {
            source = "git";
            url = "git@github.com:anthropics/claude-plugins-official.git";
          };
        };
      };
      effortLevel = "medium";
      autoUpdatesChannel = "latest";
      skipDangerousModePermissionPrompt = true;
    };
  };
}
