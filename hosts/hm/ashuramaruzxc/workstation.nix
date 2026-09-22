{ pkgs, ... }:
{
  services.protonmail-bridge.enable = true;
  programs = {
    rbw = {
      enable = true;
      settings = {
        email = "ashuramaru@tenjin-dk.com";
        base_url = "https://bitwarden.tenjin-dk.com";
        lock_timeout = 600;
        pinentry = pkgs.pinentry-qt;
      };
    };
    ghostty.settings = {
      window-height = 40;
      window-width = 140;
    };
    btop.enable = true;
    direnv.nix-direnv.package = pkgs.unstable.nix-direnv;
  };

  euvlok.home = {
    fastfetch.enable = true;
    firefox = {
      zen-browser.enable = true;
      defaultSearchEngine = "kagi";
    };
    ghostty.enable = true;
    helix.enable = true;
    mpv.enable = true;
    nh.enable = true;
    zed-editor.enable = true;
    zsh.enable = true;
    languages = {
      cpp.enable = true;
      csharp = {
        enable = true;
        version = "10";
      };
      go.enable = true;
      haskell.enable = true;
      java = {
        enable = true;
        version = "25";
      };
      javascript.enable = true;
      kotlin.enable = true;
      lisp.enable = true;
      lua.enable = true;
      python.enable = true;
      ruby.enable = true;
      rust.enable = true;
      scala.enable = true;
    };
  };
}
