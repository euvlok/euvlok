{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.hm.clankers;
  claudeAliases = {
    cc = "claude --dangerously-skip-permissions";
    op = "opencode";
  };
  codexShellAliases = {
    cx = "command codex --sandbox danger-full-access --ask-for-approval never";
  };
  codexNushellAliases = {
    cx = "^codex --sandbox danger-full-access --ask-for-approval never";
  };
in
{
  options.hm.clankers = {
    claude = {
      enable = lib.options.mkEnableOption "Claude Code";
      statusLine.enable = lib.options.mkEnableOption "agent-statusline-pi for Claude";
    };
    codex = {
      enable = lib.options.mkEnableOption "Codex";
      statusLine.enable = lib.options.mkEnableOption "agent-statusline-pi for Codex";
    };
  };

  config = lib.modules.mkMerge [
    (lib.modules.mkIf cfg.claude.enable {
      home.packages =
        (builtins.attrValues {
          inherit (pkgs.eupkgs) claude-code;
          inherit (pkgs.unstable) opencode;
        })
        ++ lib.lists.optional cfg.claude.statusLine.enable pkgs.eupkgs.agent-statusline-pi;

      programs.bash.shellAliases = claudeAliases;
      programs.zsh.shellAliases = claudeAliases;
      programs.nushell.shellAliases = claudeAliases;

      home.file.".claude/settings.json".text = builtins.toJSON (
        lib.attrsets.optionalAttrs cfg.claude.statusLine.enable {
          statusLine = {
            type = "command";
            command = lib.meta.getExe pkgs.eupkgs.agent-statusline-pi;
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
    (lib.modules.mkIf cfg.codex.enable {
      home.packages = [
        pkgs.codex-acp
        pkgs.eupkgs.codex
        pkgs.unstable.opencode
      ]
      ++ lib.lists.optional cfg.codex.statusLine.enable pkgs.eupkgs.agent-statusline-pi;

      programs.bash.shellAliases = codexShellAliases;
      programs.zsh.shellAliases = codexShellAliases;
      programs.nushell.shellAliases = codexNushellAliases;
    })
  ];
}
