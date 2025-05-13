{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nvf-source.homeManagerModules.default ];

  options.hm.nvf.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf config.hm.nvf.enable {
    programs.vim.defaultEditor = true;
    programs.nvf.enable = true;
    programs.nvf.settings.vim = {
      package = pkgs.neovim-unwrapped;
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = ",";
      };

      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };

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

      debugger = {
        nvim-dap = {
          enable = true;
          ui.enable = true;
        };
      };

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        markdown.enable = true;
        bash.enable = true;
        css.enable = true;
        yaml.enable = true;
        lua.enable = true;
        html.enable = true;
        nu.enable = true;
        python.enable = true;
      };

      visuals = {
        nvim-scrollbar.enable = true;
        nvim-web-devicons.enable = true;
        nvim-cursorline.enable = true;
        fidget-nvim.enable = true;
        highlight-undo.enable = true;
      };

      mini = {
        ai.enable = true;
        icons.enable = true;
      };

      git = {
        enable = true;
        gitsigns = {
          enable = true;
          codeActions.enable = false; # throws an annoying debug message
        };
      };

      statusline = {
        lualine.enable = true;
      };

      autocomplete = {
        nvim-cmp.enable = true;
      };

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
