{
  lib,
  makeWrapper,
  playerctl,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "lay-by-waybar-scripts";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../../../..;
    fileset = lib.fileset.unions [
      ../../../../../Cargo.lock
      ../../../../../Cargo.toml
      ../../../../../crates/dotfiles-common
      ../../../../../hosts/hm/lay-by/hyprland/scripts
    ];
  };
  cargoLock.lockFile = ../../../../../Cargo.lock;

  cargoBuildFlags = [
    "--package"
    "lay-by-waybar-scripts"
  ];
  cargoTestFlags = [
    "--package"
    "lay-by-waybar-scripts"
  ];

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/lay-by-waybar-music \
      --prefix PATH : ${lib.strings.makeBinPath [ playerctl ]}
    wrapProgram $out/bin/lay-by-waybar-nvidia \
      --prefix PATH : /run/current-system/sw/bin
  '';

  meta = {
    description = "Waybar scripts for the lay-by Hushh host";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
