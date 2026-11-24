{ config, lib, ... }: {
  imports = [
    ./agent-tools
    ./aliases.nix
    ./chromium
    ./dconf.nix
    ./firefox
    ./git.nix
    ./mitos.nix
    ../shared/nixcord.nix
    ./ssh.nix
    ./starship.nix
    ./zed.nix
  ];

  programs.codex.settings = lib.modules.mkIf config.euvlok.home.codex.enable {
    desktop.git-branch-prefix = "ashuramaruzxc";
    apps = lib.modules.mkIf config.euvlok.home.codex.desktop.enable {
      connector_76869538009648d5b282a4bb21c3d157.enabled = true; # GitHub
      connector_0c9786b2f41f41558056126bdb46c9bd.enabled = true; # GitLab
    };
  };

  programs.ghostty.settings.font-family = lib.modules.mkIf config.euvlok.home.codex.enable "Hack Nerd Font Mono";
}
