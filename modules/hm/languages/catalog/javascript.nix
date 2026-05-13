{
  pkgs,
  lib,
  versionMappings,
  getLatestVersion,
  prettierFormatter,
}:
{
  packages = builtins.attrValues {
    inherit (pkgs.unstable)
      nodejs
      bun
      deno
      yarn
      ;
    inherit (pkgs.unstable)
      sass
      pnpm
      eslint
      prettier
      biome
      package-version-server
      typescript-language-server
      ;
  };
  vscode.extensions = [
    "bradlc.vscode-tailwindcss"
    "christian-kohler.npm-intellisense"
    "denoland.vscode-deno"
    "esbenp.prettier-vscode"
    "ms-vscode.vscode-typescript-next"
    "syler.sass-indented"
  ];
  vscode.settings = {
    "[javascript]" = {
      editor.defaultFormatter = "esbenp.prettier-vscode";
      editor.formatOnPaste = true;
      editor.formatOnSave = true;
      editor.formatOnType = true;
    };
    "[typescript]" = {
      editor.formatOnPaste = true;
      editor.defaultFormatter = "esbenp.prettier-vscode";
      editor.formatOnSave = true;
    };
  };
  helix.languageServers = {
    typescript-language-server = {
      command = "typescript-language-server";
      args = [ "--stdio" ];
    };
    deno = {
      command = "deno";
      args = [ "lsp" ];
      config = {
        enable = true;
        lint = true;
        unstable = true;
        format.options.lineWidth = 120;
        format.options.indentWidth = 2;
        javascript.format.options.indentWidth = 4;
        typescript.format.options.indentWidth = 4;
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
  };
  helix.languages = [
    {
      name = "javascript";
      auto-format = true;
      indent.tab-width = 4;
      indent.unit = "    ";
      language-servers = [ "deno" ];
    }
    {
      name = "css";
      auto-format = true;
      language-servers = [ "deno" ];
    }
    {
      name = "json";
      auto-format = true;
      indent.tab-width = 2;
      indent.unit = "  ";
      language-servers = [ "deno" ];
    }
    {
      name = "typescript";
      auto-format = true;
      indent.tab-width = 4;
      indent.unit = "    ";
      language-servers = [ "deno" ];
    }
  ];
  zed.extensions = [
    "astro"
    "css-modules-kit"
    "ejs"
    "ember"
    "html-jinja"
    "jinja2"
    "less"
    "nestjs-snippets"
    "pug"
    "react-typescript-snippets"
    "scss"
    "svelte"
    "svelte-snippets"
    "tailwind-theme"
    "vue"
    "vue-snippets"
  ];
  zed.languages = {
    "JavaScript" = {
      language_servers = [
        "typescript-language-server"
        "eslint_d"
        "biome"
      ];
      formatter = prettierFormatter "javascript";
    };
    "TypeScript" = {
      language_servers = [
        "typescript-language-server"
        "eslint_d"
        "biome"
      ];
      formatter = prettierFormatter "typescript";
    };
    "TSX" = {
      language_servers = [
        "typescript-language-server"
        "eslint_d"
        "biome"
      ];
      formatter = prettierFormatter "tsx";
    };
    "JSX" = {
      language_servers = [
        "typescript-language-server"
        "eslint_d"
        "biome"
      ];
      formatter = prettierFormatter "jsx";
    };
  };
  zed.lsp = {
    "typescript-language-server".binary = {
      path = "typescript-language-server";
      arguments = [ "--stdio" ];
    };
    eslint_d.binary.path = "eslint_d";
    biome.binary = {
      path = "biome";
      arguments = [ "lsp-proxy" ];
    };
  };
}
