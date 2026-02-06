{ lib, ... }:
let
  binPaths = [
    "$HOME/.bun/bin"
    "$HOME/.npm/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.go/bin"
    "$HOME/.yarn/bin"
  ];

  bashPathStr = lib.concatStringsSep ":" binPaths;
in
{
  hm.shell.binPaths = {
    raw = binPaths;
    bash = "export PATH=\"${bashPathStr}:$PATH\"";
    zsh = "export PATH=\"${bashPathStr}:$PATH\"";
    nushell = ''
      use std/util "path add"
      ${lib.concatMapStringsSep "\n" (p: ''path add "${p}"'') binPaths}
    '';
  };
}
