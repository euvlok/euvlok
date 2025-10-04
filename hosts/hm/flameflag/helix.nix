_:
let
  repeatedBinds = {
    "{" = "page_cursor_half_up";
    "}" = "page_cursor_half_down";
    G = "goto_file_end";
    g = {
      g = "goto_file_start";
      q = ":reflow";
    };
    Z = {
      Z = ":write-quit";
      Q = ":quit!";
    };
  };
in
{
  programs.helix.defaultEditor = true;
  programs.helix.settings = {
    keys.normal = repeatedBinds;
    keys.select = repeatedBinds;
  };
}
