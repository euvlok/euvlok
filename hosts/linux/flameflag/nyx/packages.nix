{ lib, pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    # Dotfiles
    inherit (pkgs) bootstrap;
    inherit (pkgs.unstable) chezmoi sops;

    # Shells (config comes from chezmoi)
    inherit (pkgs.unstable) bash zsh;

    # Modern UNIX
    inherit (pkgs.unstable)
      atuin
      delta
      fzf
      jq
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
      catppuccin-system-theme-pi
      codex
      opencode
      yt-dlp-script
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

  system.activationScripts.removeBootstrapSelfInstall.text = ''
    bootstrap_link=/home/nyx/.local/bin/bootstrap
    if [ -L "$bootstrap_link" ]; then
      bootstrap_target="$(${lib.meta.getExe' pkgs.coreutils "readlink"} -f "$bootstrap_link" || true)"
      case "$bootstrap_target" in
        /home/nyx/.local/opt/bootstrap/*|/home/nyx/.local/opt/nix-dotfiles-bootstrap/*)
          rm -f "$bootstrap_link"
          ;;
      esac
    fi
  '';
}
