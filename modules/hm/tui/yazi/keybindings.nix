{ pkgs, ... }:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  genKeyBind = desc: on: run: { inherit desc on run; };
in
{

  programs.yazi.keymap.mgr.prepend_keymap = [
    (genKeyBind "Diff the selected with the hovered file" "d" "plugin diff")
    (genKeyBind "Move up half page" "<S-Up>" "arrow -50%")
    (genKeyBind "Move down half page" "<S-Down>" "arrow 50%")
    (genKeyBind "Move to the top" (if isDarwin then "<D-Up>" else "<C-Home>") "arrow top")
    (genKeyBind "Move to the bottom" (if isDarwin then "<D-Down>" else "<C-End>") "arrow bot")
    (genKeyBind "Enter directory or open file" "<Right>" "plugin smart-enter")
    (genKeyBind "Go to a directory interactively" [ "g" "g" ] "cd --interactive")
    (genKeyBind "Go to Config" [ "g" "c" ] "cd ~/.config")
    (genKeyBind "Go to Downloads" [ "g" "d" ] "cd ~/Downloads")
    (genKeyBind "Go to Home" [ "g" "h" ] "cd ~")
    (genKeyBind "Go to Movies" [ "g" "m" ] "cd ~/Movies")
    (genKeyBind "Go to Music" [ "g" "u" ] "cd ~/Music")
    (genKeyBind "Go to Pictures" [ "g" "p" ] "cd ~/Pictures")
    (genKeyBind "Create a new tab using the current path" "t" "tab_create --current")
    (genKeyBind "Select all files" "<C-a>" "toggle_all --state=on")
    (genKeyBind "Yank selected files (cut)" "y" "yank --cut")
    (genKeyBind "Copy files to system clipboard" "Y" "plugin system-clipboard")
    (genKeyBind "Cancel the yank status" "U" "unyank")
    (genKeyBind "Paste into hovered directory or CWD" "p" "plugin smart-paste")
    (genKeyBind "Paste into hovered directory or CWD (overwrite)" "P" "plugin smart-paste --force")
    (genKeyBind "Run a shell command" ":" "shell --interactive")
    (genKeyBind "Trash selected files" "D" "remove")
    (genKeyBind "Open shell here" "s" ''shell "$SHELL" --block'')
    (genKeyBind "Search files by content using ripgrep" "S" "search --via=rg")
  ];
}
