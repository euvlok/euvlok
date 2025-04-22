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
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.root =
      { osConfig, ... }:
      {
        imports = [
          { home.stateVersion = "24.11"; }
          inputs.catppuccin.homeModules.catppuccin
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          ../../../hm/ashuramaruzxc/nushell.nix
          ../../../hm/ashuramaruzxc/starship.nix
          ../../../hm/ashuramaruzxc/vscode.nix
          inputs.sops-nix.homeManagerModules.sops
          {
            sops = {
              age.keyFile = "$HOME/.config/sops/age/keys.txt";
              defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
            };
          }
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

    users.ashuramaru = config.home-manager.users.root;
    users.fumono = config.home-manager.users.root;
    users.minecraft = config.home-manager.users.root;

    extraSpecialArgs = { inherit inputs release; };
  };
}
