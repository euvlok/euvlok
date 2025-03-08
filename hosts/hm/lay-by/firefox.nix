{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    {
      options = {
        programs.firefox.platforms.linux.vendorPath = lib.mkOption {
          default = ".mozilla";
          description = "Path to the vendor directory for Firefox on Linux.";
          type = lib.types.str;
        };
      };
      config.programs.firefox.platforms.linux.vendorPath = ".zen";
    }
  ];

  options.hm.firefox.basicQoL = true;
  programs.firefox.package = inputs.zen-browser.packages.x86_64-linux.zen-browser;
  programs.firefox.extensions = builtins.attrValues {
    inherit (pkgs.nur.repos.rycee.firefox-addons) darkreader;
  };
}
