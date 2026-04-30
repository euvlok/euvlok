{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hm.clankers;
in
{
  options.hm.clankers = {
    claude = {
      enable = lib.mkEnableOption "Claude Code";
      statusLine.enable = lib.mkEnableOption "agent-statusline-pi for Claude";
    };
    codex = {
      enable = lib.mkEnableOption "Codex";
      statusLine.enable = lib.mkEnableOption "agent-statusline-pi for Codex";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.claude.enable {
      home.packages =
        (builtins.attrValues {
          inherit (pkgs.eupkgs) claude-code;
          inherit (pkgs.unstable) opencode;
        })
        ++ lib.optional cfg.claude.statusLine.enable pkgs.eupkgs.agent-statusline-pi;

      home.file.".claude/settings.json".text = builtins.toJSON (
        lib.optionalAttrs cfg.claude.statusLine.enable {
          statusLine = {
            type = "command";
            command = "${pkgs.eupkgs.agent-statusline-pi}/bin/agent-statusline-pi";
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
    })
    (lib.mkIf cfg.codex.enable {
      home.packages =
        [ pkgs.eupkgs.codex ]
        ++ lib.optional cfg.codex.statusLine.enable pkgs.eupkgs.agent-statusline-pi;
    })
  ];
}
