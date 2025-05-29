{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.hm.languages = {
    clojure = lib.mkEnableOption "Clojure Support";
    cpp = lib.mkEnableOption "C/C++ Support";
    csharp = lib.mkEnableOption "CSharp Support";
    dart = lib.mkEnableOption "Dart Support";
    elixir = lib.mkEnableOption "Elixir Support";
    fsharp = lib.mkEnableOption "F# Support";
    go = lib.mkEnableOption "Go Support";
    haskell = lib.mkEnableOption "Haskell Support";
    java = lib.mkEnableOption "Java Support";
    javascript = lib.mkEnableOption "JavaScript Support";
    kotlin = lib.mkEnableOption "Kotlin Support";
    lisp = lib.mkEnableOption "Lisp Support";
    lua = lib.mkEnableOption "Lua Support";
    nim = lib.mkEnableOption "Nim Support";
    ocaml = lib.mkEnableOption "OCaml Support";
    perl = lib.mkEnableOption "Perl Support";
    php = lib.mkEnableOption "PHP Support";
    python = lib.mkEnableOption "Python Support";
    ruby = lib.mkEnableOption "Ruby Support";
    rust = lib.mkEnableOption "Rust Support";
    scala = lib.mkEnableOption "Scala Support";
    swift = lib.mkEnableOption "Swift Support";
    zig = lib.mkEnableOption "Zig Support";
  };

  config = {
    home.packages =
      # Base
      (builtins.attrValues {
        inherit (pkgs)
          shellcheck
          shfmt
          bash-language-server
          taplo
          yaml-language-server
          ;
      })
      ++
        # Python
        (builtins.attrValues { inherit (pkgs) ruff; })
      ++
        # Clojure
        (lib.optionals config.hm.languages.clojure (
          builtins.attrValues {
            inherit (pkgs)
              clojure
              leiningen
              clj-kondo
              babashka
              ;
          }
        ))
      # C/C++
      ++ lib.optionals config.hm.languages.cpp (
        builtins.attrValues {
          inherit (pkgs)
            gcc
            gdb
            cmake
            ninja
            ccls
            clang-tools
            valgrind
            pkg-config
            ;
        }
      )
      # C#
      ++ lib.optionals config.hm.languages.csharp (
        builtins.attrValues {
          inherit (pkgs) omnisharp-roslyn netcoredbg;
          inherit (pkgs.dotnetCorePackages) sdk_10_0-bin sdk_8_0_3xx-bin;
        }
      )
      # Dart
      ++ lib.optionals config.hm.languages.dart (builtins.attrValues { inherit (pkgs) dart flutter; })
      # Elixir
      ++ lib.optionals config.hm.languages.elixir (
        builtins.attrValues { inherit (pkgs) elixir elixir-ls hex; }
      )
      # F#
      ++ lib.optionals config.hm.languages.fsharp (
        builtins.attrValues { inherit (pkgs) dotnet-sdk fsautocomplete; }
      )
      # Go
      ++ lib.optionals config.hm.languages.go (
        builtins.attrValues {
          inherit (pkgs)
            go
            gopls
            golangci-lint
            delve
            air
            templ
            ;
        }
      )
      # Haskell
      ++ lib.optionals config.hm.languages.haskell (
        builtins.attrValues {
          inherit (pkgs)
            ghc
            cabal-install
            stack
            haskell-language-server
            hlint
            ormolu
            ;
        }
      )
      # Java
      ++ lib.optionals config.hm.languages.java (
        builtins.attrValues {
          inherit (pkgs)
            jdt-language-server
            jdk8
            jdk17
            jdk24
            gradle
            maven
            ;
        }
      )
      # JavaScript
      ++ lib.optionals config.hm.languages.javascript (
        builtins.attrValues {
          inherit (pkgs) nodejs bun deno;
          inherit (pkgs.nodePackages)
            npm
            pnpm
            eslint
            prettier
            typescript-language-server
            ;
          inherit (pkgs) yarn;
        }
      )
      # Kotlin
      ++ lib.optionals config.hm.languages.kotlin (
        builtins.attrValues { inherit (pkgs) kotlin kotlin-language-server gradle; }
      )
      # Lisp
      ++ lib.optionals config.hm.languages.lisp (builtins.attrValues { inherit (pkgs) sbcl roswell; })
      # Lua
      ++ lib.optionals config.hm.languages.lua (
        builtins.attrValues {
          inherit (pkgs)
            lua
            luarocks
            lua-language-server
            stylua
            ;
        }
      )
      # Nim
      ++ lib.optionals config.hm.languages.nim (builtins.attrValues { inherit (pkgs) nim nimlsp; })
      # OCaml
      ++ lib.optionals config.hm.languages.ocaml (
        builtins.attrValues {
          inherit (pkgs) ocaml dune_3 opam;
          inherit (pkgs.ocamlPackages) ocaml-lsp ocamlformat;
        }
      )
      # Perl
      ++ lib.optionals config.hm.languages.perl (
        builtins.attrValues {
          inherit (pkgs) perl;
          inherit (pkgs.perlPackages) PerlLanguageServer PerlCritic PerlTidy;
        }
      )
      # PHP
      ++ lib.optionals config.hm.languages.php (
        builtins.attrValues {
          inherit (pkgs) php intelephense;
          inherit (pkgs.phpPackages) composer psalm phpstan;
        }
      )
      # Ruby
      ++ lib.optionals config.hm.languages.ruby (
        builtins.attrValues {
          inherit (pkgs)
            ruby
            bundler
            solargraph
            rubocop
            ;
          inherit (pkgs.rubyPackages) rails;
        }
      )
      # Rust
      ++ lib.optionals config.hm.languages.rust (
        builtins.attrValues {
          inherit (pkgs)
            rustc
            cargo
            rustfmt
            rust-analyzer
            clippy
            cargo-watch
            cargo-edit
            cargo-outdated
            ;
        }
      )
      # Scala
      ++ lib.optionals config.hm.languages.scala (
        builtins.attrValues {
          inherit (pkgs)
            scala
            sbt
            metals
            scalafmt
            ;
        }
      )
      # Swift
      ++ lib.optionals config.hm.languages.swift (
        builtins.attrValues { inherit (pkgs) swift swift-format sourcekit-lsp; }
      )
      # TypeScript
      ++ lib.optionals config.hm.languages.typescript (
        builtins.attrValues {
          inherit (pkgs) nodejs bun yarn;
          inherit (pkgs.nodePackages)
            npm
            pnpm
            typescript
            typescript-language-server
            eslint
            prettier
            ;
        }
      )
      ++ lib.optionals config.hm.languages.zig (builtins.attrValues { inherit (pkgs) zig zls; });
  };
}
