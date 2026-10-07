{
  lib,
  stdenv,
  fetchzip,
  cmake,
  ninja,
  pkg-config,
  vulkan-headers,
  vulkan-loader,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lsfg-vk";
  version = "2.0.0";

  src = fetchzip {
    url = "https://git.lsfg-vk.dev/lsfg-vk/snapshot/lsfg-vk-${finalAttrs.version}.tar.xz";
    hash = "sha256-vp0/adJdVV73C2RFjcEE90KjWiZJQhiqqOlYQ89RG+Y=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qttools
    qt6.qtwayland
  ];

  cmakeFlags = [
    "-DLSFGVK_BUILD_LAYER=ON"
    "-DLSFGVK_BUILD_UI=ON"
    "-DLSFGVK_BUILD_CLI=ON"
    "-DLSFGVK_MANAGED=ON"
    "-DLSFGVK_LAYER_LIBRARY_PATH=${placeholder "out"}/lib/liblsfg-vk-layer.so"
  ];

  postFixup = ''
    patchelf --add-rpath "${lib.getLib vulkan-loader}/lib" "$out/bin/lsfg-vk-cli"
  '';

  meta = {
    description = "Lossless Scaling frame generation Vulkan layer";
    homepage = "https://lsfg-vk.dev";
    license = lib.licenses.cc-by-nc-nd-40;
    mainProgram = "lsfg-vk-ui";
    platforms = [ "x86_64-linux" ];
  };
})
