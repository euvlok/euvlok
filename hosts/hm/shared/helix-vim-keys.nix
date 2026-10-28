_:
let
  repeatedBinds = {
    "{" = "page_cursor_half_up";
    "}" = "page_cursor_half_down";
    Z = {
      Z = ":write-quit";
      Q = ":quit!";
    };
  };
in
{
  programs.helix.defaultEditor = true;
  programs.helix.settings = {
    # Preserve counted G navigation and the fork's built-in Z folding bindings
    keys.normal = repeatedBinds // {
      G = "goto_line";
      g = {
        g = "goto_file_start";
        q = ":reflow";
      };
    };
    # Select-mode motions must extend rather than discard the selection
    keys.select = repeatedBinds // {
      G = "extend_to_file_end";
      g = {
        g = "extend_to_file_start";
        q = ":reflow";
      };
    };
  };
}
