{ pkgs, lib, ... }:
let
  getExe = pkg: lib.getExe pkgs.${pkg};

  ruffFmt = {
    command = getExe "ruff";
    args = [
      "format"
      "-"
    ];
  };

  nixfmtFmt.command = getExe "nixfmt-rfc-style";

  shfmtFmt = {
    command = getExe "shfmt";
    args = [ "-w" ];
  };

  denoCmd = getExe "deno";
  denoFmt = argsAdd: {
    command = denoCmd;
    args = [
      "fmt"
      "-"
    ] ++ argsAdd;
  };

  denoFmtJsTs = denoFmt [
    "--options-line-width=100"
    "--options-indent-width=4"
  ];
  denoFmtCss = denoFmt [ ];
  denoFmtJson = denoFmt [
    "--options-line-width=100"
    "--options-indent-width=2"
  ];

  yamlFmt = {
    command = getExe "yaml-language-server";
    args = [
      "--format"
      "-"
    ];
  };

  taploFmt = {
    command = getExe "taplo";
    args = [
      "fmt"
      "-"
    ];
  };

  denoLs = [ "deno" ];
  yamlLs = [ "yaml-language-server" ];
  taploLs = [ "taplo" ];

  bashLsCfg = {
    command = getExe "bash-language-server";
    args = [ "start" ];
    config.enable = true;
  };

  nilLsCfg = {
    command = getExe "nil";
    config.nil.formatting.command = [ (getExe "nixfmt-rfc-style") ];
  };

  ruffLsCfg = {
    command = getExe "ruff-lsp";
    config = {
      settings = {
        lint.enable = true;
        organizeImports = true;
        format = {
          enable = true;
          lineLength = 100;
        };
      };
    };
  };

  denoLsCfg = {
    command = denoCmd;
    args = [ "lsp" ];
    config = {
      enable = true;
      lint = true;
      unstable = true;
      suggest.imports.hosts = {
        "https://deno.land" = true;
        "https://cdn.nest.land" = true;
        "https://crux.land" = true;
      };
      inlayHints = {
        enumMemberValues.enabled = true;
        functionLikeReturnTypes.enabled = true;
        parameterNames.enabled = "all";
        parameterTypes.enabled = true;
        propertyDeclarationTypes.enabled = true;
        variableTypes.enabled = true;
      };
    };
  };

  yamlLsCfg = {
    command = getExe "yaml-language-server";
    args = [ "--stdio" ];
    config = {
      yaml = {
        format.enable = true;
        validation = true;
        schemas.https = true;
      };
    };
  };

  taploLsCfg = {
    command = getExe "taplo";
    args = [
      "lsp"
      "stdio"
    ];
    config.formatter = {
      alignEntries = true;
      columnWidth = 100;
    };
  };

  indent4 = {
    tab-width = 4;
    unit = "    ";
  };
  indent2 = {
    tab-width = 2;
    unit = "  ";
  };

  languageDefinitions = [
    {
      name = "python";
      formatter = ruffFmt;
      language-servers = [ "ruff-lsp" ];
    }
    {
      name = "nix";
      formatter = nixfmtFmt;
      language-servers = [ "nil" ];
    }
    {
      name = "bash";
      diagnostic-severity = "warning";
      formatter = shfmtFmt;
      language-servers = [ "bash-language-server" ];
    }
    {
      name = "javascript";
      indent = indent4;
      formatter = denoFmtJsTs;
      language-servers = denoLs;
    }
    {
      name = "typescript";
      indent = indent4;
      formatter = denoFmtJsTs;
      language-servers = denoLs;
    }
    {
      name = "css";
      formatter = denoFmtCss;
      language-servers = denoLs;
    }
    {
      name = "json";
      indent = indent2;
      formatter = denoFmtJson;
      language-servers = denoLs;
    }
    {
      name = "yaml";
      formatter = yamlFmt;
      language-servers = yamlLs;
    }
    {
      name = "toml";
      formatter = taploFmt;
      language-servers = taploLs;
    }
  ];

  finalLanguages = languageDefinitions |> lib.map (lang: lang // { auto-format = true; });
in
{
  programs.helix.languages = {
    language-server = {
      bash-language-server = bashLsCfg;
      nil = nilLsCfg;
      ruff-lsp = ruffLsCfg;
      deno = denoLsCfg;
      yaml-language-server = yamlLsCfg;
      taplo = taploLsCfg;
    };
    language = finalLanguages;
  };
}
