{ pkgs, ... }:
{
  home.packages = builtins.attrValues { inherit (pkgs) font-awesome; };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [ (builtins.fromJSON (builtins.readFile ./waybar.json)) ];
    style = builtins.readFile ./waybar.css;
  };
}
