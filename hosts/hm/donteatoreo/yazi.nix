{ pkgs, ... }:
let
  genKeyBind = (pkgs.callPackage ../../../modules/hm/tui/yazi/lib.nix { }).genKeyBind;

  keymap = [
    (genKeyBind "Go to a directory interactively" [
      "g"
      "g"
    ] "cd --interactive")
    (genKeyBind "Go to the Config directory" [
      "g"
      "c"
    ] "cd ~/.config")
    (genKeyBind "Go to the Downloads directory" [
      "g"
      "d"
    ] "cd ~/Downloads")
    (genKeyBind "Go to the Home directory" [
      "g"
      "h"
    ] "cd ~/")
    (genKeyBind "Go to the Movies directory" [
      "g"
      "m"
    ] "cd ~/Movies")
    (genKeyBind "Go to the Music directory" [
      "g"
      "u"
    ] "cd ~/Music")
    (genKeyBind "Go to the Pictures directory" [
      "g"
      "p"
    ] "cd ~/Pictures")
  ];
in
{
  programs.yazi.keymap.manager.keymap = keymap;
}
