_:
let
  aliases = {
    v = "hx";
    vi = "hx";
    vim = "hx";
    h = "hx";
    bc = "bc -l";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
    htop = "btop";
    neofetch = "fastfetch";
  };
in
{
  programs.bash.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}
