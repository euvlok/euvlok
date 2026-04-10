{ pkgs, ... }:
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    statusLine = {
      type = "command";
      command = "${pkgs.claude-statusline}/bin/claude-statusline";
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
    env = {
      "_ZO_DOCTOR" = "0";
    };
    effortLevel = "medium";
    autoUpdatesChannel = "latest";
    skipDangerousModePermissionPrompt = true;
  };
}
