_: {
  nixpkgs.overlays = [
    (final: prev: {
      jemalloc = prev.jemalloc.overrideAttrs (finalAttrs: {
        version = "5.3.1";
        src = final.fetchurl {
          url = "https://github.com/jemalloc/jemalloc/releases/download/${finalAttrs.version}/jemalloc-${finalAttrs.version}.tar.bz2";
          hash = "sha256-OCa8gCMvIu1cRmLzA095nKMW6BkQO9x7uZAYpCFwb5I=";
        };
        configureFlags = [
          "--with-version=${finalAttrs.version}-0-g0"
          "--with-lg-vaddr=${
            with final.stdenv.hostPlatform; toString (if isILP32 then 32 else parsed.cpu.bits)
          }"
        ]
        ++ final.lib.optionals (final.stdenv.hostPlatform.isPower && final.stdenv.hostPlatform.isLLVM) [
          "--with-lg-page=16"
        ];
      });
    })
  ];
}
