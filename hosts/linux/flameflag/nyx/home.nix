{
  inputs,
  lib,
  eulib,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.nyx =
    { osConfig, ... }:
    {
      imports =
        let
          config = [
            { home.stateVersion = "25.05"; }
          ]
          ++ [
            inputs.sops-nix-trivial.homeManagerModules.sops
            {
              sops = {
                age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
                defaultSopsFile = ../../../../secrets/flameflag.yaml;
                secrets.github_ssh = { };
              };
            }
          ]
          ++ [
            ../../../hm/flameflag/aliases.nix
            inputs.self.homeModules.default
            inputs.self.homeModules.os
            {
              hm = {
                chromium.browser = "brave";
                chromium.enable = true;
                fastfetch.enable = true;
                firefox.enable = true;
                firefox.zen-browser.enable = true;
                ghostty.enable = true;
                helix.enable = true;
                jujutsu.enable = true;
                mpv.enable = true;
                nixcord.enable = true;
                nushell.enable = true;
                vscode.enable = true;
                yazi.enable = true;
                zed-editor.enable = true;
                zellij.enable = true;
              };
            }
          ]
          ++ (
            let
              hmExtraConfigModules = [
                "ghostty"
                "git"
                "helix"
                "jujutsu"
                "nixcord"
                "nushell"
                "ssh"
                "starship"
                "vscode"
                "yazi"
                "zed"
              ];
            in
            lib.flatten (map (n: [ ../../../hm/flameflag/${n}.nix ]) hmExtraConfigModules)
          )
          ++ lib.optionals osConfig.services.desktopManager.gnome.enable [
            ../../../hm/flameflag/dconf.nix
          ];
        in
        config;
    };
}
