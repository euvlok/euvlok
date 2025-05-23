{ inputs, config, ... }:
let
  release = builtins.fromJSON (config.system.nixos.release);

  commonUsers = [
    { home.stateVersion = "25.05"; }
    ../../../hm/ashuramaruzxc/nushell.nix
    ../../../hm/ashuramaruzxc/starship.nix
    ../../../hm/ashuramaruzxc/vscode.nix
    ../shared/aliases.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
    inputs.sops-nix-trivial.homeManagerModules.sops
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
        ghostty.enable = true;
        git.enable = true;
        helix.enable = true;
        nh.enable = true;
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
in
{
  imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
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
        ] ++ commonUsers;
      };
    users.fumono =
      { osConfig, ... }:
      {
        imports = [
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
          ../../../hm/2husecondary/git.nix
        ] ++ commonUsers;
      };
    users.minecraft =
      { osConfig, ... }:
      {
        imports = [
          { catppuccin = { inherit (osConfig.catppuccin) enable accent flavor; }; }
        ] ++ commonUsers;
      };

    extraSpecialArgs = { inherit inputs release; };
  };
}
