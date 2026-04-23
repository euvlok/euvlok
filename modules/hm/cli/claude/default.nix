{
  pkgs,
  lib,
  config,
  ...
}:
let
  codexConfig = {
    projects = builtins.listToAttrs (
      map
        (path: {
          name = path;
          value.trust_level = "trusted";
        })
        [
          "${config.home.homeDirectory}/Developer/codex"
          "${config.home.homeDirectory}/Developer/eupkgs"
          "${config.home.homeDirectory}/Developer/euvlok"
        ]
    );
  };
in
{
  options.hm.claude.statusLine.enable = lib.mkEnableOption "Claude statusline";

  config = {
    home.packages = builtins.attrValues {
      inherit (pkgs.eupkgs)
        claude-code
        claude-statusline
        opencode
        codex
        ;
    };
    home.file.".codex/config.toml".source =
      (pkgs.formats.toml { }).generate "codex-config.toml" codexConfig;
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
