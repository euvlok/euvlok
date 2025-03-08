_:
let
  editors = {
    v = "hx";
    vi = "hx";
    vim = "hx";
    h = "hx";
  };

  misc = {
    bc = "bc -l";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
  };

  programs = {
    htop = "btop";
    neofetch = "fastfetch";
  };
in
editors // misc // programs
