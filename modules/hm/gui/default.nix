{ euvlokInputs }:
{ lib, ... }:
{
  imports = [
    (lib.modules.importApply ./chromium { inherit euvlokInputs; })
    (lib.modules.importApply ./firefox { inherit euvlokInputs; })
    ./mpv.nix
    (lib.modules.importApply ./nixcord { inherit euvlokInputs; })
    ./zed.nix
  ];

  euvlok.home.zed-editor.enable = lib.modules.mkDefault true;
}
