{
  inputs,
  pkgs,
  osConfig,
  ...
}:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${osConfig.nixpkgs.hostPlatform.system}.forVSCodeVersion
      pkgs.vscode.version
    )
    vscode-marketplace
    ;
in
{
  mkExt = p: e: vscode-marketplace.${p}.${e};
}
