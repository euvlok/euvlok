{ determinateNix, pkgs }:
let
  # Use the tool's own lock so its unmodified libraries can come from cache
  components = determinateNix.lib.makeComponents {
    pkgs = import determinateNix.inputs.nixpkgs {
      inherit (pkgs.stdenv.hostPlatform) system;
    };
  };
  traced = components.overrideScope (
    _: previous: {
      nix-expr = previous.nix-expr.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          cp ${./trace-accessor.hh} input-trace.hh
          substituteInPlace eval.cc \
            --replace-fail '#include <algorithm>' '#include "input-trace.hh"
          #include <algorithm>' \
            --replace-fail 'accessor = makeCachingSourceAccessor(accessor);' \
              'accessor = makeCachingSourceAccessor(accessor);
                  if (auto trace = getEnv("EUVLOK_SOURCE_TRACE"))
                      accessor = make_ref<InputTraceAccessor>(accessor, *trace);'
        '';
      });
    }
  );
in
traced.nix-cli
