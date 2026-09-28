{ lib, config, ... }:
{
  config = lib.modules.mkIf config.euvlok.home.zellij.enable {
    programs.zellij.settings = {
      on_force_close = lib.modules.mkDefault "detach";
      scroll_buffer_size = lib.modules.mkDefault 100000;
      show_startup_tips = lib.modules.mkDefault false;
      show_release_notes = lib.modules.mkDefault false;
    };
  };
}
