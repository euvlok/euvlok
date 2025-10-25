_: {
  programs.ghostty = {
    clearDefaultKeybinds = true;
    settings = {
      command = "zsh -l -c 'nu -l -e zellij'";
      font-family = "MonaspiceKr Nerd Font";
      font-size = 18;
    };
  };
}
