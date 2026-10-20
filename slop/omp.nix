{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.euvlok.home.codex.omp;
  codexDir = config.home.sessionVariables.CODEX_HOME;
  claudeDir = config.programs.claude-code.configDir;
  settingsFile = (pkgs.formats.json { }).generate "omp-settings.json" cfg.settings;
  syncSettings = pkgs.writeShellApplication {
    name = "omp-sync-settings";
    text = ''
      exec ${lib.meta.getExe pkgs.python3} ${./omp.py} \
        --omp ${lib.meta.getExe cfg.package} \
        --settings ${settingsFile} \
        ${lib.escapeShellArgs (
          lib.concatMap (path: [
            "--skill-root"
            path
          ]) cfg.skillRoots
        )}
    '';
  };
in
{
  options.euvlok.home.codex.omp = {
    enable = lib.options.mkEnableOption "Oh My Pi alongside Codex";
    package = lib.options.mkPackageOption pkgs "omp" {
      default = [
        "unstable"
        "omp"
      ];
    };
    settings = lib.options.mkOption {
      type = lib.types.attrsOf (pkgs.formats.json { }).type;
      default = { };
      example = {
        "defaultThinkingLevel" = "high";
        "skills.enabled" = true;
      };
      description = ''
        Settings keyed by OMP's dotted setting names. Applied through
        `omp config set` on activation, preserving unrelated runtime settings.
        Credentials must be configured outside Nix.
      '';
    };
    skillRoots = lib.options.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional trees searched for SKILL.md files on activation. Their
        containing skill collections are added to skills.customDirectories.
      '';
    };
  };

  config = lib.modules.mkIf (config.euvlok.home.codex.enable && cfg.enable) {
    euvlok.home.codex.omp = {
      settings = lib.mapAttrs (_: lib.modules.mkDefault) {
        symbolPreset = "ascii";
        emojiAutocomplete = false;
        "composer.shape" = "claude";
        "tui.tight" = true;
        "tui.reactions" = false;
        "statusLine.preset" = "compact";
        enabledProviders = [
          "claude"
          "codex"
          "gemini"
        ];
        "skills.enabled" = true;
        "skills.enableSkillCommands" = true;
        "skills.enableClaudeUser" = true;
        "skills.enableClaudeProject" = true;
        "skills.enableCodexUser" = true;
        "skills.enablePiUser" = true;
        "skills.enablePiProject" = true;
        "skills.enableAgentsUser" = true;
        "skills.enableAgentsProject" = true;
        "skills.customDirectories" = [ "${codexDir}/skills/.system" ];
      };
      skillRoots = [
        "${codexDir}/plugins/cache"
        "${claudeDir}/skills/synced"
        "${config.home.homeDirectory}/.gemini/antigravity/skills"
        "${config.home.homeDirectory}/.gemini/antigravity-cli/skills"
      ];
    };

    home.packages = [ cfg.package ];
    home.file.".omp/agent/APPEND_SYSTEM.md".text = ''
      Use plain, concise language and plain-text command descriptions.
      Do not use emojis in responses, commands, command titles, shell output
      labels, or commit messages. Use ordinary text for progress and results.

      Follow the applicable AGENTS.md, CLAUDE.md, and GEMINI.md instructions.
      Use relevant discovered skills, read their SKILL.md before applying them,
      and follow their referenced resources. Do not assume another agent's
      tools exist here; use available equivalents and explain missing tools.

      Complete authorized work, verify changes with the project's configured
      checks, and report the result and any remaining limitations directly.
    '';
    home.activation.ompSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${lib.meta.getExe syncSettings}
    '';
  };
}
