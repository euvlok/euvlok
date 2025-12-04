{
  inputs,
  eulib,
  pkgsUnstable,
}:
{
  baseImports = [
    { home.stateVersion = "25.05"; }
    ../../../../pkgs/catppuccin-gtk.nix
    inputs.catppuccin-trivial.homeModules.catppuccin
  ];

  catppuccinConfig =
    { osConfig, ... }:
    {
      catppuccin = {
        inherit (osConfig.catppuccin) enable accent flavor;
      };
    };

  rootHmConfig = {
    hm = {
      bash.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      helix.enable = true;
      nh.enable = true;
      zellij.enable = true;
      zsh.enable = true;
    };
  };

  baseHomeManager = {
    imports = [ inputs.home-manager-ashuramaruzxc.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      extraSpecialArgs = { inherit inputs eulib pkgsUnstable; };
    };
  };
}
