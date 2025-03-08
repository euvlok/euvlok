{
  inputs,
  pkgs,
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
    users.unsigned-int32 = {
      imports = [
        { home.stateVersion = "24.11"; }
        inputs.catppuccin.homeModules.catppuccin

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
        { home.packages = builtins.attrValues { inherit (pkgs) ani-cli thefuck; }; }
      ];
    };
    extraSpecialArgs = { inherit inputs release; };
  };
}
