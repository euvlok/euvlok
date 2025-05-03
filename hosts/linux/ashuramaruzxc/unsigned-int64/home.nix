{
  inputs,
  config,
  ...
}:
let
  release = builtins.fromJSON (config.system.nixos.release);

  commonUsers = [
    { home.stateVersion = "24.11"; }
    # ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/starship.nix
    ../../../hm/ashuramaruzxc/vscode.nix
    inputs.catppuccin.homeModules.catppuccin
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
        direnv.enable = true;
        fastfetch.enable = true;
        fzf.enable = true;
        git.enable = true;
        # nushell.enable = true;
        nvf.enable = true;
        helix.enable = true;
        ssh.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zsh.enable = true;
      };
    }
  ];
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
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
        ] ++ commonUsers;
      };
    users.ashuramaru =
      { osConfig, ... }:
      {
        imports = [
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          { config.hm.vscode.enable = true; }
        ] ++ commonUsers;
      };
    users.fumono =
      { osConfig, ... }:
      {
        imports = [
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          { config.hm.vscode.enable = true; }
        ] ++ commonUsers;
      };
    users.minecraft =
      { osConfig, ... }:
      {
        imports = [
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          { config.hm.vscode.enable = true; }
        ] ++ commonUsers;
      };

    extraSpecialArgs = { inherit inputs release; };
  };
}
