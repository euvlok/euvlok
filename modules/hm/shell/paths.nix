{ lib, ... }:
let
  binDirs = [
    ".bun"
    ".npm"
    ".local"
    ".cargo"
    ".go"
    "go"
    ".yarn"
    ".deno"
    ".ghcup"
    ".local/share/pnpm"
  ];
  binPaths = map (dir: "$HOME/${dir}/bin") binDirs;
  bashPathStr = lib.concatStringsSep ":" binPaths;
  nuList = "[ " + (lib.concatStringsSep " " (map (d: "\"${d}\"") binDirs)) + " ]";
in
{
  hm.shell.binPaths = {
    raw = binPaths;
    bash = "export PATH=\"${bashPathStr}:$PATH\"";
    zsh = "export PATH=\"${bashPathStr}:$PATH\"";
    nushell = ''
      use std/util "path add"
      ${nuList} | each {|dir| $"($env.HOME)/($dir)/bin" } | path add $in
    '';
  };
}
