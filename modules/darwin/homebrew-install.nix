{ homebrewSource, homebrewTaps }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  prefix = config.homebrew.prefix;
  library = "${prefix}/Library";
  source = homebrewSource.inputs.brew-src;
  lock = builtins.fromJSON (builtins.readFile "${homebrewSource}/flake.lock");
  version = lock.nodes.brew-src.original.ref;
  ruby = pkgs.ruby_4_0;
  brew = pkgs.runCommand "brew-${version}" { nativeBuildInputs = [ pkgs.gnused ]; } ''
    cp -R ${source} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/Library/Homebrew/cmd/update.sh" \
      --replace-fail 'for DIR in "''${HOMEBREW_REPOSITORY}"' 'for DIR in '
    cat >> "$out/Library/Homebrew/utils/ruby.sh" <<'RUBY'
    setup-ruby-path() { export HOMEBREW_RUBY_PATH="${ruby}/bin/ruby"; }
    RUBY
    cat >> "$out/Library/Homebrew/vendor/bundle/bundler/setup.rb" <<'RUBY'
    $:.unshift "${ruby.gems.fiddle}/${ruby.gemPath}/gems/fiddle-${ruby.gems.fiddle.version}/lib"
    RUBY
    sed -i \
      -e 's/^HOMEBREW_VERSION=.*/HOMEBREW_VERSION="${version}"/' \
      -e 's/^GIT_REVISION=.*/GIT_REVISION=""; HOMEBREW_VERSION="${version}"/' \
      "$out/Library/Homebrew/brew.sh"
  '';
  taps = pkgs.runCommand "homebrew-taps" { } (
    "mkdir -p \"$out\"\n"
    + lib.concatMapAttrsStringSep "\n" (name: path: ''
      mkdir -p "$out/${builtins.head (lib.splitString "/" name)}"
      cp -RH ${lib.escapeShellArg (toString path)} "$out/${name}"
    '') homebrewTaps
  );
  launcher = pkgs.replaceVarsWith {
    name = "brew";
    src = pkgs.writeText "brew.in" (
      ''
        #!/bin/bash
        export HOMEBREW_PREFIX=${lib.escapeShellArg prefix}
        export HOMEBREW_LIBRARY=${lib.escapeShellArg library}
        export HOMEBREW_REPOSITORY="$HOMEBREW_LIBRARY/.homebrew-is-managed-by-nix"
        export HOMEBREW_BREW_FILE="@out@"
        export HOMEBREW_UPDATE_BEFORE=nix
        export HOMEBREW_UPDATE_AFTER=nix
        export HOMEBREW_NO_AUTO_UPDATE=1
        export HOMEBREW_NO_INSTALL_FROM_API=1
      ''
      + builtins.readFile "${homebrewSource}/modules/brew.tail.sh"
    );
    isExecutable = true;
    dontPatchShebangs = true;
    replacements = {
      out = builtins.placeholder "out";
      runtimePath = lib.makeBinPath [ pkgs.gitMinimal ];
    };
  };
  install = pkgs.writeShellScript "homebrew-install" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:/usr/bin:/bin:/usr/sbin:/sbin
    if [[ $(id -u) != 0 ]]; then
      printf >&2 'Homebrew installation requires root\n'
      exit 1
    fi
    # Keep existing packages and preserve mutable code before adopting the prefix
    install_link() {
      local path=$1 target=$2 backup=$1.before-ndw index=0
      if [[ -L $path && $(readlink -- "$path") == "$target" ]]; then
        return
      fi
      if [[ -e $path || -L $path ]]; then
        while [[ -e $backup || -L $backup ]]; do
          index=$((index + 1))
          backup=$path.before-ndw.$index
        done
        mv -- "$path" "$backup"
      fi
      ln -s "$target" "$path"
    }
    for directory in "" bin etc include lib sbin share opt var Cellar Caskroom Frameworks Library; do
      /usr/bin/install -d -o ${lib.escapeShellArg config.homebrew.user} -g admin -m 0755 \
        ${lib.escapeShellArg prefix}/"$directory"
    done
    install_link ${lib.escapeShellArg "${library}/Homebrew"} ${brew}/Library/Homebrew
    install_link ${lib.escapeShellArg "${library}/Taps"} ${taps}
    /usr/bin/install -d -o ${lib.escapeShellArg config.homebrew.user} -g admin -m 0775 \
      ${lib.escapeShellArg "${library}/.homebrew-is-managed-by-nix/.git"}
    touch ${lib.escapeShellArg "${library}/.homebrew-is-managed-by-nix/.git/HEAD"}
    install_link ${lib.escapeShellArg "${prefix}/bin/brew"} ${launcher}
  '';
in
{
  # ndw's preflight requires an existing brew, so fresh hosts run this first
  system.build.homebrew-install = install;
  system.activation.steps.homebrew-install = {
    deps = [ "users" ];
    text = "${install}";
  };
  system.activation.steps.homebrew.deps = [ "homebrew-install" ];
  homebrew.global.auto.update = false;
  homebrew.on.activation.auto.update = lib.mkForce false;
  homebrew.zsh.integration.enable = true;
  homebrew.bash.integration.enable = true;
}
