{
  lib,
  fetchFromGitHub,
  libX11,
  libXdamage,
  libXext,
  libXfixes,
  libxcb,
  nix-update-script,
  python3Packages,
  qt6,
  vulkan-headers,
  vulkan-loader,
  wayland,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "linux-rt-upscaler";
  # renovate: datasource=github-tags depName=linux-rt-upscaler packageName=baronsmv/linux-rt-upscaler
  version = "1.1.6.post1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "baronsmv";
    repo = "linux-rt-upscaler";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GVPT1bghDzadt5ijZuPQ0v24uczjJWAPeZwvUXLxHvI=";
  };

  postPatch = ''
    substituteInPlace src/upscaler/env.py \
      --replace-fail 'ctypes.CDLL("libX11.so.6")' 'ctypes.CDLL("${libX11}/lib/libX11.so.6")'
  '';

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    libX11
    libXdamage
    libXext
    libXfixes
    libxcb
    qt6.qtbase
    vulkan-headers
    vulkan-loader
    wayland
  ];

  build-system = [ python3Packages.setuptools ];

  dependencies = [
    python3Packages.pillow
    python3Packages.pyside6
    python3Packages.pyyaml
    python3Packages.shiboken6
    python3Packages.xcffib
  ];

  postInstall = ''
    install -Dm444 data/applications/io.github.baronsmv.linux-rt-upscaler.desktop \
      $out/share/applications/io.github.baronsmv.linux-rt-upscaler.desktop
    substituteInPlace $out/share/applications/io.github.baronsmv.linux-rt-upscaler.desktop \
      --replace-fail EXEC_PATH_PLACEHOLDER upscale-gui
    install -Dm444 data/icons/hicolor/256x256/apps/io.github.baronsmv.linux-rt-upscaler.png \
      -t $out/share/icons/hicolor/256x256/apps
    install -Dm444 data/icons/hicolor/scalable/apps/io.github.baronsmv.linux-rt-upscaler.svg \
      -t $out/share/icons/hicolor/scalable/apps
  '';

  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  pythonImportsCheck = [ "upscaler" ];

  passthru.updateScript = nix-update-script {
    attrPath = "linux-rt-upscaler";
    extraArgs = [
      "--flake"
      "--format"
    ];
  };

  meta = {
    description = "Real-time SRCNN upscaler for X11 and XWayland windows";
    homepage = "https://redirect.github.com/baronsmv/linux-rt-upscaler";
    changelog = "https://redirect.github.com/baronsmv/linux-rt-upscaler/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "upscale-gui";
    platforms = lib.systems.doubles.linux;
  };
})
