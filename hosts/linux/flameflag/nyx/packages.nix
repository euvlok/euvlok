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
      delta
      fzf
      pfetch-rs
      television
      ;

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
      yazi
      zed-editor
      vscode
      zellij
      zoxide
      ;

    inherit (pkgs.eupkgs)
      claude-code
      claude-statusline
      opencode
      ;

    # Linux desktop bits the dotfiles assume
    inherit (pkgs.unstable)
      ghostty
      wl-clipboard
      ;

    git = pkgs.unstable.git.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        sed -i "s|export GITPERLLIB='\(.*\)'|export GITPERLLIB='\1:${
          pkgs.unstable.perlPackages.makePerlPath [ pkgs.unstable.perlPackages.EmailValid ]
        }'|" \
          $out/libexec/git-core/git-send-email
      '';
    });

    # Telegram (was in the old configuration)
    inherit (pkgs) telegram-desktop;
  };
}
