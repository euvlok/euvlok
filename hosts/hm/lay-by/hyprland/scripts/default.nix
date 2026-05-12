{
  lib,
  makeWrapper,
  playerctl,
  stdenv,
  zig_0_16,
}:

stdenv.mkDerivation {
  pname = "lay-by-waybar-scripts";
  version = "0-unstable";

  src = ./src;

  nativeBuildInputs = [
    makeWrapper
    zig_0_16
  ];

  doCheck = true;

  postFixup = ''
    wrapProgram $out/bin/lay-by-waybar-music \
      --prefix PATH : ${lib.makeBinPath [ playerctl ]}
    wrapProgram $out/bin/lay-by-waybar-nvidia \
      --prefix PATH : /run/current-system/sw/bin
  '';

  meta = {
    description = "Zig Waybar scripts for the lay-by Hushh host";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
