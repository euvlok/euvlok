_:
let
  editor = {
    # Core
    format.on-save = true;
    files.auto-save.focus-lost = false;
    idle-timeout = 50;

    # Visual
    cursor = {
      highlight-line = true;
      shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };
    };
    gutters.layout = [
      "diagnostics"
      "line-numbers"
      "spacer"
      "diff"
    ];
    indent-guides.render = true;
    line-number = "relative";
    rulers.columns = [
      72
      80
    ];
    statusline = {
      right = [
        "diagnostics"
        "selections"
        "register"
        "search-position"
        "position"
        "position-percentage"
        "file-encoding"
      ];
      mode.color = true;
    };
    whitespace.characters = {
      nbsp = "⍽";
      newline = "⏎";
      space = "·";
      tab = "→";
      tabpad = "·";
    };

    # LSP and Completion
    completion = {
      replace = true;
      trigger-length = 1;
    };
    lsp = {
      messages.enable = true;
      inlay-hints.enable = true;
    };

    # File and Buffer
    bufferline.show = "always";
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

    mouse.enable = true;
  };
in
{
  euvlok.home.mitos.settings = {
    inherit editor;
    terminal.true-color = true;
    keys = {
      normal = {
        space.space = "file_picker";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
      select = { };
    };
  };
}
