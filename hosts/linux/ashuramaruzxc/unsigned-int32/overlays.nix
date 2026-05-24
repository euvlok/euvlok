{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: _prev: {
      gtk-nocsd = final.stdenv.mkDerivation {
        pname = "gtk-nocsd";
        version = "4.0";

        src = final.fetchFromGitea {
          domain = "codeberg.org";
          owner = "MorsMortium";
          repo = "GTK-NoCSD";
          rev = "ecd66fe95850b2416ba85fbfcac9f0d248837dcf";
          hash = "sha256-PHP5KSld1FrQCHj3Xdt+juBqGU3au7LWh976B1YtFPY=";
        };

        nativeBuildInputs = [ final.pkg-config ];
        buildInputs = [
          final.glib
          final.libadwaita
        ];

        installPhase = ''
          runHook preInstall

          install -Dm755 libgtk-nocsd.so.0 "$out/lib/libgtk-nocsd.so.0"
          ln -s libgtk-nocsd.so.0 "$out/lib/libgtk-nocsd.so"

          install -Dm644 LICENSE "$out/share/licenses/gtk-nocsd/LICENSE"
          install -Dm644 README.md "$out/share/doc/gtk-nocsd/README.md"
          install -Dm644 Source/gtk-nocsd.sh "$out/share/doc/gtk-nocsd/examples/profile.d/gtk-nocsd.sh"
          install -Dm644 Source/gtk-nocsd.csh "$out/share/doc/gtk-nocsd/examples/profile.d/gtk-nocsd.csh"

          runHook postInstall
        '';

        meta = {
          description = "LD_PRELOAD library to disable GTK client side decorations";
          homepage = "https://codeberg.org/MorsMortium/GTK-NoCSD";
          license = final.lib.licenses.gpl3Plus;
          platforms = final.lib.platforms.linux;
        };
      };

      gtk3-nocsd = final.gtk-nocsd;
      libgtk-nocsd0 = final.gtk-nocsd;
      libgtk3-nocsd0 = final.gtk-nocsd;
    })
  ];

  environment = {
    systemPackages = [ pkgs.gtk-nocsd ];
    sessionVariables.LD_PRELOAD = "${pkgs.gtk-nocsd}/lib/libgtk-nocsd.so";
  };
}
