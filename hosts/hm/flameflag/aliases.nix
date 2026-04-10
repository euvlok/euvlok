{ pkgs, lib, ... }:
let
  aliases = {
    # AI Aliases
    c = "claude";
    cc = "claude";
    o = "opencode";
    oo = "opencode";

    v = "hx";
    vi = "hx";
    vim = "hx";
    h = "hx";
    bc = "bc -l";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
    htop = "btop";
    neofetch = "fastfetch";
  }
  // lib.optionalAttrs (pkgs.stdenvNoCC.isDarwin) {
    micfix = "sudo killall coreaudiod";
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
