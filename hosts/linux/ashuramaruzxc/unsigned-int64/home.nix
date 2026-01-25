{
  inputs,
  eulib,
  ...
}:
let
  homeCommon = import ../shared/home/common.nix { inherit inputs eulib; };
  homeBaseUsers = import ../shared/home/base-users.nix {
    inherit (homeCommon) baseImports baseHomeManager;
  };
  inherit (homeCommon)
    catppuccinConfig
    rootHmConfig
    ;

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

  userImports = {
    root = [ rootHmConfig ] ++ commonHmConfig;
    ashuramaru = commonHmConfig;
    fumono = commonHmConfig;
    minecraft = commonHmConfig;
  };

in
homeBaseUsers {
  inherit userImports globalImports;
}
