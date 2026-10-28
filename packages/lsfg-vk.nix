{
  basePackage,
  lib,
  ninja,
  pkg-config,
  qt6,
}:

basePackage.overrideAttrs (previous: {
  nativeBuildInputs = previous.nativeBuildInputs ++ [
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = previous.buildInputs ++ [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qttools
    qt6.qtwayland
  ];

  cmakeFlags = previous.cmakeFlags ++ [
    (lib.cmakeBool "LSFGVK_BUILD_LAYER" true)
    (lib.cmakeBool "LSFGVK_BUILD_UI" true)
    (lib.cmakeBool "LSFGVK_BUILD_CLI" true)
  ];

  # Preserve upstream's late Vulkan RPATH patch on the actual CLI
  # Automatic Qt wrapping would replace it before that patch runs
  dontWrapQtApps = true;
  postFixup = previous.postFixup + ''
    wrapQtApp "$out/bin/lsfg-vk-ui"
  '';

  meta = previous.meta // {
    mainProgram = "lsfg-vk-ui";
    platforms = [ "x86_64-linux" ];
  };
})
