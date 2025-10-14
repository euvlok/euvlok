{
  inputs,
  pkgsUnstable,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nvf-source.homeManagerModules.default ];

  options.hm.nvf.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf config.hm.nvf.enable {
    programs.vim.defaultEditor = true;
    home.sessionVariables = {
      EDITOR = lib.mkForce "nvim";
    };
    programs.nvf.enable = true;
    programs.nvf.settings.vim = {
      package = pkgsUnstable.neovim-unwrapped;
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = ",";
      };

      binds.whichKey.enable = true;
      binds.cheatsheet.enable = true;

      lsp = {
        enable = true;
        formatOnSave = true;
        lspkind.enable = false;
        lightbulb.enable = true;
        lspsaga.enable = false;
        trouble.enable = true;
        lspSignature.enable = true;
        otter-nvim.enable = true;
        nvim-docs-view.enable = true;
      };

      debugger.nvim-dap.enable = true;
      debugger.nvim-dap.ui.enable = true;

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        # Always enabled languages
        nix.enable = true;
        markdown.enable = true;
        bash.enable = true;
        html.enable = true;
        yaml.enable = true;
        # css.enable = true;

        clang.enable = config.hm.languages.cpp.enable; # It handles both C/C++
        clojure.enable = config.hm.languages.clojure.enable;
        csharp.enable = config.hm.languages.csharp.enable;
        dart.enable = config.hm.languages.dart.enable;
        elixir.enable = config.hm.languages.elixir.enable;
        fsharp.enable = config.hm.languages.fsharp.enable;
        go.enable = config.hm.languages.go.enable;
        haskell.enable = config.hm.languages.haskell.enable;
        kotlin.enable = config.hm.languages.kotlin.enable;
        lua.enable = config.hm.languages.lua.enable;
        nim.enable = config.hm.languages.nim.enable;
        nu.enable = config.programs.nushell.enable;
        ocaml.enable = config.hm.languages.ocaml.enable;
        php.enable = config.hm.languages.php.enable;
        python.enable = config.hm.languages.python.enable;
        ruby.enable = config.hm.languages.ruby.enable;
        rust.enable = config.hm.languages.rust.enable;
        scala.enable = config.hm.languages.scala.enable;
        ts.enable = config.hm.languages.javascript.enable; # It handles both JS/TS
      };

      visuals = {
        nvim-scrollbar.enable = true;
        nvim-web-devicons.enable = true;
        nvim-cursorline.enable = true;
        fidget-nvim.enable = true;
        highlight-undo.enable = true;
      };

      mini.ai.enable = true; # AI here stands for `a`/`i` textobjects
      mini.icons.enable = true;

      git = {
        enable = true;
        gitsigns = {
          enable = true;
          codeActions.enable = false; # throws an annoying debug message
        };
      };

      statusline.lualine.enable = true;
      autocomplete.nvim-cmp.enable = true;

      utility = {
        snacks-nvim.enable = true;
        motion.leap.enable = true;
        direnv.enable = config.programs.direnv.enable;
        yazi-nvim.enable = config.programs.yazi.enable;
        surround.enable = true;
      };

      telescope.enable = true;
      treesitter.enable = true;
    };
  };
}
