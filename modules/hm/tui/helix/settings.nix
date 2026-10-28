_:
let
  editor = {
    # Core
    auto-format = true;
    auto-save = false;
    idle-timeout = 100;
    completion-timeout = 50;

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
      "code-action-hint"
      "spacer"
      "diff"
    ];
    indent-guides.render = true;
    line-number = "relative";
    popup-border = "all";
    rounded-corners = true;
    rainbow-brackets = true;
    rulers = [
      72
      80
    ];
    statusline = {
      center = [ "version-control" ];
      right = [
        "diagnostics"
        "workspace-diagnostics"
        "selections"
        "register"
        "position"
        "position-percentage"
        "file-type"
      ];
    };
    true-color = true;
    # Fork options: github.com/gj1118/helix/blob/9e56642/README.md
    breadcrumb = {
      enable = true;
      path = "file";
    };
    # The fork gates inline diagnostic rendering separately from severity
    inline-diagnostics = {
      show-virtual-lines = true;
      cursor-line = "warning";
    };
    whitespace.render = {
      space = "none";
      newline = "none";
      tab = "all";
      nbsp = "all";
    };
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
      display-progress-messages = true;
      auto-document-highlight = true;
      inlay-hints-length-limit = 50;
    };
    word-completion = {
      enable = true;
      trigger-length = 4;
    };

    # File and Buffer
    bufferline.render-mode = "always";
    buffer-picker.start-position = "previous";
    file-picker = {
      git-global = true;
      git-ignore = true;
      hidden = false;
    };
    # Unlike the picker, the fork's explorer ignores no ignore files by default
    file-explorer = {
      hidden = false;
      parents = true;
      ignore = true;
      git-ignore = true;
      git-global = true;
      git-exclude = true;
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
    keys = {
      normal = {
        space.space = "file_picker";
        esc = [
          "save_selection"
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
      select = { };
    };
  };
}
