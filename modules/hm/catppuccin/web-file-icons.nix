{ lib, pkgs }:
let
  inherit ((pkgs.callPackage ../../../lib/firefox-addons.nix { })) buildFirefoxXpiAddon;
in
buildFirefoxXpiAddon {
  pname = "catppuccin-web-file-icons";
  version = "1.7.1";
  addonId = "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}";
  url = "https://addons.mozilla.org/firefox/downloads/file/5255034/catppuccin_web_file_icons-1.7.1.xpi";
  sha256 = "sha256-T7IvPw/ad5PrG0zS3810V6zePWP654oD8Ktv0oUjhlM=";
  meta = {
    homepage = "https://redirect.github.com/catppuccin/web-file-explorer-icons";
    description = "Soothing pastel icons for file explorers on the web!";
    license = lib.licenses.mit;
    mozPermissions = [
      "storage"
      "contextMenus"
      "activeTab"
      "*://bitbucket.org/*"
      "*://codeberg.org/*"
      "*://git.sr.ht/*"
      "*://gitea.com/*"
      "*://github.com/*"
      "*://gitlab.com/*"
      "*://hg.sr.ht/*"
      "*://tangled.org/*"
    ];
    platforms = lib.systems.doubles.all;
  };
}
