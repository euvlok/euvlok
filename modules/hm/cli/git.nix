{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:

{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkMerge [
    (lib.mkIf config.hm.git.enable {
      programs = {
        gitui.enable = true;
        gh.enable = true;
        git = {
          enable = true;
          package = pkgs.gitMinimal; # We don't use SVN; we also don't need GUI, manual, Python support, or PCRE2
          ignores = [
            "*.DS_Store"
            "*.swp"
            ".DS_Store"
            "Thumbs.db"
            "result"
            "result*"
          ];
          aliases = {
            grep = "!sh -c 'rg --vimgrep --color=always --line-number --no-heading --smart-case \"$@\"' _";
          };
          # Inspired by https://blog.gitbutler.com/how-git-core-devs-configure-git/
          extraConfig = {
            branch.sort = "-committerdate"; # Sort branches by most recent commit
            column.ui = "auto"; # Display branches, tags, etc. in columns
            commit.verbose = true; # Show diff of changes in commit message editor
            core.fsmonitor = true; # Useful for big repos e.g nixpkgs; enables background file system monitoring
            core.untrackedCache = true; # useful in conjunction with fsmonitor; speeds up finding untracked files
            diff.algorithm = "histogram"; # Better quality diffs
            diff.colorMoved = "plain"; # Highlight moved lines distinctly
            diff.mnemonicPrefix = true; # Show i/, w/, c/ prefixes in diff headers
            diff.renames = true;
            fetch.prune = true; # Remove remote-tracking branches that no longer exist on the remote
            fetch.pruneTags = true; # Remove local tags that no longer exist on the remote
            help.autocorrect = "prompt"; # Suggest corrections for mistyped commands and prompt
            init.defaultBranch = "trunk";
            merge.conflictstyle = "zdiff3"; # Shows the common ancestor in merge conflicts for more context
            pull.rebase = true; # Use rebase instead of merge for `git pull`
            push.autoSetupRemote = true; # Automatically set upstream on first push to new branch
            push.followTags = true;
            rebase.autoSquash = true; # Automatically arrange fixup!/squash! commits during interactive rebase
            rebase.autoStash = true; # Automatically stash changes before rebase and apply after
            rebase.updateRefs = true; # Keep stacked branches up-to-date when rebasing
            rerere.autoupdate = true; # Automatically stage files if conflicts were auto-resolved by rerere
            rerere.enabled = true; # Reuse recorded resolutions of conflicted merges
            tag.sort = "version:refname"; # Sort tags like versions (e.g., v1.10 after v1.2)
          };
        };
        vscode.profiles.default.userSettings = {
          git.enableCommitSigning = if (config.programs.git.signing.key != null) then true else false;
        };
      };
    })
    (lib.mkIf (osConfig.nixpkgs.hostPlatform.isDarwin) {
      home.file.".gitconfig".source =
        config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/.gitconfig";
    })
  ];
}
