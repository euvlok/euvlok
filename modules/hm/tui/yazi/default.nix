{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isLinux;
in
{
  imports = [
    ./keybindings.nix
    ./settings.nix
  ];

  options.euvlok.home.yazi.enable = lib.options.mkEnableOption "Yazi";

  config = lib.modules.mkIf config.euvlok.home.yazi.enable {
    home.packages =
      (builtins.attrValues { inherit (pkgs) mediainfo exiftool; })
      ++ lib.lists.optionals isLinux [
        pkgs.wl-clipboard
        pkgs.xclip
      ];
    programs.yazi = {
      enable = true;
      package = pkgs.unstable.yazi;
      shellWrapperName = "yy";
      plugins = {
        inherit (pkgs.unstable.yaziPlugins)
          diff
          full-border
          smart-enter
          smart-paste
          ;
        system-clipboard = ./system-clipboard.yazi;
      }
      // lib.attrsets.optionalAttrs config.programs.git.enable {
        inherit (pkgs.unstable.yaziPlugins) git;
      }
      // lib.attrsets.optionalAttrs config.programs.starship.enable {
        inherit (pkgs.unstable.yaziPlugins) starship;
      };
      initLua = ''
        local function setup_plugin(name, opts)
          local ok, plugin = pcall(require, name)
          if ok and type(plugin.setup) == "function" then
            if opts == nil then
              plugin:setup()
            else
              plugin:setup(opts)
            end
          end
        end

        setup_plugin("full-border")
        ${lib.strings.optionalString config.programs.git.enable ''setup_plugin("git", { order = 1500 })''}
        ${lib.strings.optionalString config.programs.starship.enable ''setup_plugin("starship")''}
      '';
    };
  };
}
