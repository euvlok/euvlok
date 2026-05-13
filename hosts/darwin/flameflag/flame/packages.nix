{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    # Dotfiles
    inherit (pkgs.unstable) chezmoi sops;

    # Shells (config comes from chezmoi)
    inherit (pkgs.unstable) bash zsh;

    # Modern UNIX
    inherit (pkgs.unstable)
      atuin
      delta # diff
      fzf
      pfetch-rs # neofetch
      television # tv
      ;

    # TUI
    inherit (pkgs.unstable)
      nix-tree
      ;

    # Development
    inherit (pkgs.unstable)
      gh
      gitui
      helix
      jujutsu
      nushell
      starship
      uv
      yazi
      zed-editor
      vscode
      zellij
      zoxide
      ;

    inherit (pkgs.eupkgs)
      agent-statusline
      agent-statusline-pi
      codex
      opencode
      yt-dlp-script
      ;

    git = pkgs.unstable.git.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        sed -i "s|export GITPERLLIB='\(.*\)'|export GITPERLLIB='\1:${
          pkgs.unstable.perlPackages.makePerlPath [ pkgs.unstable.perlPackages.EmailValid ]
        }'|" \
          $out/libexec/git-core/git-send-email
      '';
    });
  };
}
