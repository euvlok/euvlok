{
  applyEuvlokInputs,
  applyEuvlokInputsWith,
}:
{
  core = applyEuvlokInputsWith ../../modules/hm/core.nix { includeNixpkgs = false; };
  default = applyEuvlokInputsWith ../../modules/hm/common.nix { includeNixpkgs = true; };
  integrated = applyEuvlokInputsWith ../../modules/hm/common.nix { includeNixpkgs = false; };
  server = applyEuvlokInputs ../../modules/hm/server.nix;
  os = applyEuvlokInputs ../../modules/hm/os;
  nixpkgs = applyEuvlokInputs ../../modules/hm/nixpkgs.nix;
  catppuccin = {
    imports = [
      (applyEuvlokInputs ../../modules/hm/os)
      (applyEuvlokInputs ../../modules/hm/catppuccin)
    ];
  };
  catppuccin-gtk = {
    imports = [
      (applyEuvlokInputs ../../modules/hm/os)
      (applyEuvlokInputs ../../modules/hm/catppuccin-gtk.nix)
    ];
  };
  sops = applyEuvlokInputs ../../modules/hm/sops.nix;
  cli = ../../modules/hm/cli;
  chromium = applyEuvlokInputs ../../modules/hm/gui/chromium;
  firefox = applyEuvlokInputs ../../modules/hm/gui/firefox;
  gui = applyEuvlokInputs ../../modules/hm/gui;
  hyprland = ../../modules/hm/wm/hyprland;
  languages = {
    imports = [
      ../../modules/hm/languages
      ../../modules/hm/tui/helix
      ../../modules/hm/gui/vscode
      ../../modules/hm/gui/zed.nix
    ];
  };
  shell = ../../modules/hm/shell;
  terminal = ../../modules/hm/terminal;
  tui = ../../modules/hm/tui;
  wm = ../../modules/hm/wm;
}
