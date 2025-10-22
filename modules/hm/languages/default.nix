{
  pkgs,
  pkgsUnstable,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isLinux;

  versionMappings = {
    java =
      let
        versions = [
          "8"
          "11"
          "17"
          "21"
          "24"
        ];
      in
      lib.genAttrs versions (version: pkgsUnstable."jdk${version}");

    dotnet =
      let
        versions = [
          "8"
          "9"
          "10"
        ];
      in
      lib.genAttrs versions (version: pkgsUnstable.dotnetCorePackages."sdk_${version}_0-bin");
  };

  getLatestVersion = mapping: lib.last (lib.sort lib.versionOlder (lib.attrNames mapping));

  languageDefinitions = {
    clojure = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          clojure
          leiningen
          clj-kondo
          babashka
          ;
      };
    };
    cpp = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          ccls
          clang
          clang-tools
          cmake
          gdb
          gnumake
          ninja
          pkg-config
          valgrind
          ;
      };
    };
    csharp = {
      packages = builtins.attrValues { inherit (pkgsUnstable) omnisharp-roslyn netcoredbg; };
      versionMap = versionMappings.dotnet;
      defaultVersion = getLatestVersion versionMappings.dotnet;
    };
    dart = {
      packages = builtins.attrValues { inherit (pkgsUnstable) flutter; };
    };
    elixir = {
      packages = builtins.attrValues { inherit (pkgsUnstable) elixir elixir-ls hex; };
    };
    fsharp = {
      packages = builtins.attrValues { inherit (pkgsUnstable) dotnet-sdk fsautocomplete; };
    };
    go = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          go
          gopls
          golangci-lint
          delve
          air
          templ
          ;
      };
    };
    haskell = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          ghc
          cabal-install
          stack
          haskell-language-server
          hlint
          ormolu
          ;
      };
    };
    java = {
      packages = builtins.attrValues { inherit (pkgsUnstable) jdt-language-server gradle maven; };
      versionMap = versionMappings.java;
      defaultVersion = getLatestVersion versionMappings.java;
    };
    javascript = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          nodejs
          bun
          deno
          yarn
          ;
        inherit (pkgsUnstable)
          sass
          pnpm
          eslint
          prettier
          typescript-language-server
          ;
      };
    };
    kotlin = {
      packages = builtins.attrValues { inherit (pkgsUnstable) kotlin kotlin-language-server gradle; };
    };
    lisp = {
      packages = builtins.attrValues { inherit (pkgsUnstable) sbcl roswell; };
    };
    lua = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          lua
          luarocks
          lua-language-server
          stylua
          ;
      };
    };
    nim = {
      packages = builtins.attrValues { inherit (pkgsUnstable) nim nimlsp; };
    };
    ocaml = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable) ocaml dune_3 opam;
        inherit (pkgsUnstable.ocamlPackages) ocaml-lsp ocamlformat;
      };
    };
    perl = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable) perl;
        inherit (pkgsUnstable.perlPackages) PerlLanguageServer PerlCritic PerlTidy;
      };
    };
    php = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable) php intelephense;
        inherit (pkgsUnstable.phpPackages) composer psalm phpstan;
      };
    };
    python =
      let
        python312 = pkgsUnstable.python312.withPackages (pip: [
          pip.black
          pip.flake8
          pip.ipython
          pip.isort
          pip.jupyter
          pip.mypy
          pip.pylint
          pip.ruff
          pip.jedi
          pip.python-lsp-server
        ]);
      in
      {
        packages = builtins.attrValues { python = python312; };
      };
    ruby = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable) ruby_3_4 solargraph rubocop;
        inherit (pkgsUnstable.rubyPackages)
          rails
          # rails-dom-testing
          # rails-html-sanitizer
          ruby-lsp
          ;
      };
    };
    rust = {
      packages = builtins.attrValues {
        inherit (pkgs.rust-bin.stable.latest) default;
        inherit (pkgsUnstable)
          # cargo
          # rustfmt
          rust-analyzer
          # clippy
          cargo-watch
          cargo-edit
          cargo-outdated
          ;
      };
    };
    scala = {
      packages = builtins.attrValues {
        inherit (pkgsUnstable)
          scala
          sbt
          metals
          scalafmt
          ;
      };
    };
    swift = {
      packages = builtins.attrValues { inherit (pkgsUnstable) swift swift-format sourcekit-lsp; };
    };
    zig = {
      packages = builtins.attrValues { inherit (pkgsUnstable) zig zls; };
    };
  };
in
{
  imports = [
    ./helix.nix
    ./vscode.nix
    ./zed.nix
  ];

  options.hm.languages = lib.mapAttrs (
    name: def:
    lib.mkOption {
      default = { };
      description = lib.options.mdDoc "Manages the development environment for the ${lib.strings.toSentenceCase name} language";
      type =
        if def ? versionMap then
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              version = lib.mkOption {
                type = lib.types.enum (lib.attrNames def.versionMap);
                default = def.defaultVersion;
                description = lib.options.mdDoc ''
                  Select the version of the ${lib.strings.toSentenceCase name} SDK to install

                  **Available versions:**
                  ${lib.concatStringsSep "\n" (map (v: "- `${v}`") (lib.attrNames def.versionMap))}

                  The default is `${def.defaultVersion}`
                '';
              };
              extraPackages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = lib.options.mdDoc ''
                  A list of extra packages to install alongside the standard ${lib.strings.toSentenceCase name} toolchain
                '';
              };
            };
          }
        else
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = lib.options.mdDoc "Enable the development environment and tools for ${lib.strings.toSentenceCase name}";
              };
              extraPackages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
                description = lib.options.mdDoc ''
                  A list of extra packages to install alongside the standard ${lib.strings.toSentenceCase name} toolchain.
                '';
              };
            };
          };
    }
  ) languageDefinitions;

  config =
    let
      enabledLanguages = lib.filterAttrs (
        name: value: config.hm.languages.${name}.enable
      ) languageDefinitions;

      enabledLanguagePackageLists = lib.mapAttrsToList (
        name: def:
        let
          langCfg = config.hm.languages.${name};
          basePackages = def.packages or [ ];
          versionedPackage = if (def ? versionMap) then [ def.versionMap.${langCfg.version} ] else [ ];
          extraPkgs = langCfg.extraPackages;
        in
        basePackages ++ versionedPackage ++ extraPkgs
      ) enabledLanguages;
    in
    {
      # assertions = [
      #   {
      #     assertion = (config.hm.languages.haskell.enable && isLinux);
      #     message = "Haskell is currently not supported on macOS (Darwin)";
      #   }
      # ];

      home.packages =
        (builtins.attrValues {
          inherit (pkgsUnstable)
            shellcheck
            shfmt
            bash-language-server
            taplo
            yaml-language-server
            ;
        })
        ++ (lib.flatten enabledLanguagePackageLists);
    };
}
