_: {
  imports = [
    ./hack.nix
    ./keepassxc.nix
    ./niri.nix
    ./nixcord.nix
    ./noctalia.nix
    ./spicetify.nix
    ./stylix.nix
    ./vicinae.nix
  ];

  hm = {
    chromium = {
      enable = true;
      browser = "ungoogled-chromium";
    };
    zed-editor.enable = true;
  };
}
