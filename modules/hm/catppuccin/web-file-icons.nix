{ lib, pkgs }:
let
  inherit ((pkgs.callPackage ../../../lib/firefox-addons.nix { })) buildFirefoxXpiAddon;
in
buildFirefoxXpiAddon {
  pname = "catppuccin-web-file-icons";
  version = "1.6.1";
  addonId = "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}";
  url = "https://addons.mozilla.org/firefox/downloads/file/4647055/catppuccin_web_file_icons-1.6.1.xpi";
  sha256 = "sha256-oe4jEr0ssTBqON7EtQ7cVaQ5edgYczJk3ulVxsBKdnY=";
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
      "*://gitea.com/*"
      "*://github.com/*"
      "*://gitlab.com/*"
      "*://tangled.org/*"
    ];
    platforms = lib.systems.doubles.all;
  };
}
