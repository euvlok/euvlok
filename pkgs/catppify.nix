{ pkgs, lib, ... }:
pkgs.stdenvNoCC.mkDerivation {
  pname = "catppify";
  version = "0-unstable-2024-12-07";

  src = pkgs.fetchFromGitHub {
    owner = "raluvy95";
    repo = "catppify";
    rev = "3162e3c8ec1e4fcc02f563014b1efb0f91206268";
    hash = "sha256-I2NCXTjGvsZKvs8la5Xq0tWAPti6CglxwjjAgLm0/Ac=";
  };

  installPhase = ''
    runHook preInstall
    # Patch the python script to use dirname(__file__) for palette
    sed -i '
      s|SRC_DIR = path.realpath(__file__).strip("catppify")|SRC_DIR = path.dirname(path.realpath(__file__))|
      s|CLUT_PATH = path.realpath(f"{SRC_DIR}/palette/{args.palette}/noise_{args.noise}.png")|CLUT_PATH = path.join(SRC_DIR, "palette", args.palette, f"noise_{args.noise}.png")|
    ' catppify
    mkdir -p "$out/bin"
    cp catppify "$out/bin/catppify.py"
    cp -r palette "$out/bin/"
    cat > "$out/bin/catppify" <<EOF
    #!/bin/sh
    cd "\$(dirname "\$0")"
    exec ${
      lib.getExe (pkgs.python312.withPackages (ps: builtins.attrValues { inherit (ps) pillow; }))
    } catppify.py "\$@"
    EOF
    chmod +x "$out/bin/catppify"
    runHook postInstall
  '';
}
