{ inputs, ... }:
{
  imports = [ inputs.nixos-vscode-server-trivial.nixosModules.default ];

  services.vscode-server.enable = true;
}
