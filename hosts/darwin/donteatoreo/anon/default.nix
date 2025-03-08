{ inputs, ... }:
let
  username = "anon";
in
{
  anons-Mac-mini = inputs.nix-darwin-donteatoreo.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ./fonts.nix
      ./home.nix
      ./zsh.nix

      {
        nixpkgs.hostPlatform.system = "aarch64-darwin";

        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
          shell = inputs.nixpkgs-donteatoreo.legacyPackages.aarch64-darwin.zsh;
        };

        system.stateVersion = 4;
      }

      ../../../../modules/cross
      {
        cross = {
          nix.enable = true;
          nixpkgs.enable = true;
          nixpkgs.allowUnfree = true;
        };
      }
    ];
  };
}
