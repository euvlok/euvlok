{
  inputs,
  eulib,
  ...
}:
let
  baseImports = [
    { home.stateVersion = "25.11"; }
    ../../../../modules/hm/catppuccin-gtk.nix
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

  commonHmConfig = [
    inputs.self.homeModules.default
    inputs.self.homeModules.os
    inputs.self.homeConfigurations.ashuramaruzxc
    {
      hm = {
        fastfetch.enable = true;
        ghostty.enable = true;
        helix.enable = true;
        nh.enable = true;
        nushell.enable = true;
        vscode.enable = true;
        yazi.enable = true;
        zellij.enable = true;
      };
    }
  ];

  globalImports = [
    ../shared/home/aliases.nix
    catppuccinConfig
    inputs.sops-nix-trivial.homeManagerModules.sops
    {
      sops = {
        age.keyFile = "$HOME/.config/sops/age/keys.txt";
        defaultSopsFile = ../../../../secrets/ashuramaruzxc_unsigned-int64.yaml;
      };
    }
  ];
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs eulib; };
  };

  home-manager.users.root = {
    imports = baseImports ++ globalImports ++ [ rootHmConfig ] ++ commonHmConfig;
  };

  home-manager.users.ashuramaru = {
    imports = baseImports ++ globalImports ++ commonHmConfig;
  };

  home-manager.users.fumono = {
    imports = baseImports ++ globalImports ++ commonHmConfig;
  };

  home-manager.users.minecraft = {
    imports = baseImports ++ globalImports ++ commonHmConfig;
  };
}
