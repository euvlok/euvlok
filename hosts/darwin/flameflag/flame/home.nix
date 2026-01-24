{
  inputs,
  pkgs,
  eulib,
  config,
  ...
}:
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.${config.system.primaryUser} =
    { config, osConfig, ... }:
    {
      imports = [
        { home.stateVersion = "25.05"; }
      ]
      ++ [
        inputs.sops-nix-trivial.homeManagerModules.sops
        {
          sops = {
            age.keyFile = "${config.home.homeDirectory}/sops/age/keys.txt";
            defaultSopsFile = ../../../../secrets/flameflag.yaml;
            secrets.github_ssh = { };
          };
        }
      ]
      ++ [
        {
          home.file."warp/themes".source = "${pkgs.warp-terminal-catppuccin.outPath}/share/warp/themes";
          home.file."Documents/catppuccin-userstyles.json".source =
            "${pkgs.catppuccin-userstyles.outPath}/dist/import.json";
        }
      ]
      ++ [
        {
          catppuccin = {
            enable = true;
            flavor = "frappe";
            accent = "blue";
          };
        }
      ]
      ++ [
        inputs.self.homeModules.default
        inputs.self.homeModules.os
        inputs.self.homeConfigurations.flameflag
        {
          hm = {
            fastfetch.enable = true;
            ghostty.enable = true;
            helix.enable = true;
            jujutsu.enable = true;
            nixcord.enable = true;
            nushell.enable = true;
            ssh.enable = true;
            vscode.enable = true;
            yazi.enable = true;
            zed-editor.enable = true;
            zellij.enable = true;
          };
        }
      ];
    };
}
