{ packages }:
{ lib, pkgs, ... }:
let
  fonts = pkgs.runCommand "darwin-fonts" { nativeBuildInputs = [ pkgs.findutils ]; } ''
    mkdir -p "$out/Nix Fonts"
    while IFS= read -r -d "" font; do
      target="$out/Nix Fonts/''${font#${builtins.storeDir}/}"
      mkdir -p "''${target%/*}"
      ln -s "$font" "$target"
    done < <(find -L ${lib.escapeShellArgs packages} -type f \
      -regex '.*\.\(ttf\|ttc\|otf\|dfont\)' -print0)
  '';
in
{
  system.activation.steps.fonts = {
    deps = [ "files" ];
    text = ''
      mkdir -p /Library/Fonts
      ${pkgs.rsync}/bin/rsync --archive --copy-links --delete-during \
        ${lib.escapeShellArg "${fonts}/Nix Fonts"} /Library/Fonts/
    '';
  };
}
