_:
let
  editor = {
    # Core
    auto-format = true;
    auto-save = true;
    idle-timeout = 50;

    # Visual
    color-modes = true;
    cursorline = true;
    cursor-shape = {
      insert = "bar";
      normal = "block";
      select = "underline";
    };
    gutters = [
      "diagnostics"
      "line-numbers"
      "spacer"
      "diff"
    ];
    indent-guides.render = true;
    line-number = "relative";
    rulers = [
      72
      80
    ];
    statusline.center = [ "position-percentage" ];
    true-color = true;
    whitespace.characters = {
      nbsp = "⍽";
      newline = "⏎";
      space = "·";
      tab = "→";
      tabpad = "·";
      trail = "•";
    };

    # LSP and Completion
    completion-replace = true;
    completion-trigger-len = 1;
    lsp = {
      display-messages = true;
      display-inlay-hints = true;
    };

    # File and Buffer
    bufferline = "always";
    file-picker = {
      git-global = true;
      git-ignore = true;
      hidden = false;
    };
    soft-wrap.enable = true;

    # Search
    search = {
      smart-case = true;
      wrap-around = true;
    };

    mouse = true;
  };
in
{
  programs.helix.settings = {
    inherit editor;
    normal = {
      space.space = "file_picker";
      esc = [
        "collapse_selection"
        "keep_primary_selection"
      ];
    };
    select = { };
  };
}
