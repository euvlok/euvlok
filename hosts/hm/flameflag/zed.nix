_: {
  programs.zed-editor.extensions = [
    "zed-mcp-server-context7"
  ];
  programs.zed-editor.userSettings = {
    buffer_font_family = "MonaspiceKr Nerd Font";
    buffer_font_size = 20;
    ensure_final_newline_on_save = true;
    remove_trailing_whitespace_on_save = true;
    ui_font_family = "MonaspiceKr Nerd Font";
    ui_font_size = 20;
    context_servers = {
      Context7 = {
        command = {
          path = "npx";
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
        };
        settings = { };
      };
    };
  };
}
