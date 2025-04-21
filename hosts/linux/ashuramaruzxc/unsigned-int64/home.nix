{
  inputs,
  config,
  ...
}:
let
  release =
    if builtins.hasAttr "darwinRelease" config.system then
      builtins.fromJSON (config.system.darwinRelease)
    else
      builtins.fromJSON (config.system.nixos.release);
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ashuramaru =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "24.11"; }
          inputs.catppuccin.homeModules.catppuccin
          { inherit (osConfig) catppuccin; }

          ../../../../modules/hm
          {
            hm = {
              bash.enable = true;
              fastfetch.enable = true;
              fzf.enable = true;
              nixcord.enable = true;
              nushell.enable = true;
              nvf.enable = true;
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zellij.enable = true;
              zsh.enable = true;
            };
          }
        ];
      };
    extraSpecialArgs = { inherit inputs release; };
  };
}
