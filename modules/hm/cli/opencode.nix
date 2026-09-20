{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.euvlok.home.opencode;
  ghAllow = lib.hm.dag.entryAfter [ "gh *" ] "allow";
in
{
  options.euvlok.home.opencode.enable = lib.options.mkEnableOption "OpenCode";

  config = lib.modules.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.unstable.opencode;
      settings = {
        share = "disabled";
        autoupdate = false;
        snapshot = true;
        references.opencode = {
          repository = "anomalyco/opencode";
          description = "Use for current OpenCode implementation, configuration, SDK, and documentation details; compare behavior with the installed release.";
        };
        watcher.ignore = [
          "**/.git/**"
          "**/.jj/**"
          "**/.cache/**"
          "**/.ansible/**"
          "**/.venv/**"
          "**/.ruby-lsp/**"
          "**/.gradle/**"
          "**/node_modules/**"
          "**/__pycache__/**"
          "**/*.egg-info/**"
          "**/.zig-cache/**"
          "**/zig-cache/**"
          "**/zig-pkg/**"
          "**/zig-out/**"
          "**/target/**"
          "**/build/**"
          "**/build-*/**"
          "**/builddir/**"
          "**/.build/**"
          "**/dist/**"
          "**/result/**"
          "**/tmp/**"
          "**/.bluebuild-scripts_*/**"
        ];
        tool_output = {
          max_lines = 600;
          max_bytes = 32 * 1024;
        };
        compaction.prune = true;
        permission = {
          "*" = "allow";
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "~/.ssh/**" = "deny";
            "~/.config/gh/**" = "deny";
            "~/.local/share/opencode/auth.json" = "deny";
            "~/.config/opencode/auth.json" = "deny";
          };
          external_directory."*" = "allow";
          bash = {
            "*" = "allow";
            sudo = "ask";
            "sudo *" = "ask";
            rm = "ask";
            "rm *" = "ask";
            rmdir = "ask";
            "rmdir *" = "ask";
            unlink = "ask";
            "unlink *" = "ask";
            "git commit*" = "ask";
            "git push*" = "ask";
            "git send-pack*" = "ask";
            "git-push*" = "ask";
            "git-send-pack*" = "ask";
            "git lfs push*" = "ask";
            "jj git push*" = "ask";
            "jj gerrit upload*" = "ask";
            "git reset*" = "ask";
            "git restore*" = "ask";
            "git clean*" = "ask";
            "git checkout*" = "ask";
            "git switch*" = "ask";
            "git rebase*" = "ask";
            "git merge*" = "ask";
            "git cherry-pick*" = "ask";
            "git stash*" = "ask";
            gh = "ask";
            "gh *" = "ask";
            "gh pr view*" = ghAllow;
            "gh pr list*" = ghAllow;
            "gh issue view*" = ghAllow;
            "gh issue list*" = ghAllow;
            "gh run view*" = ghAllow;
            "gh run list*" = ghAllow;
            "gh repo view*" = ghAllow;
            "gh repo list*" = ghAllow;
            "gh release view*" = ghAllow;
            "gh release list*" = ghAllow;
          };
        };
      };
      tui = {
        keybinds = {
          session_copy = "ctrl+t";
          variant_cycle = "ctrl+shift+t";
        };
        attention = {
          enabled = true;
          notifications = true;
          sound = true;
          volume = 0.4;
          sound_pack = "opencode.default";
        };
      };
    };
  };
}
