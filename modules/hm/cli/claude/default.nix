{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.hm.claude.enable = lib.mkEnableOption "Claude & Claude Status Line";

  config = lib.mkIf config.hm.claude.enable {
    home.packages = builtins.attrValues {
      inherit (pkgs.eupkgs)
        claude-code
        claude-statusline
        codex
        ;
    };
    inherit (pkgs.unstable) opencode;
    home.file.".claude/settings.json".text = builtins.toJSON (
      lib.optionalAttrs config.hm.claude.statusLine.enable {
        statusLine = {
          type = "command";
          command = "${pkgs.eupkgs.claude-statusline}/bin/claude-statusline";
        };
      }
      // {
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
      }
    );
  };
}
