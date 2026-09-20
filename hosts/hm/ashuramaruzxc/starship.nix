_: {

  home.sessionVariables.VIRTUAL_ENV_DISABLE_PROMPT = "1";

  programs.starship.enable = true;
  programs.starship.settings = {
    scan_timeout = 30;
    command_timeout = 1000;
    add_newline = false;
    format = "[\\[](bold red)$username[@](bold green)$hostname $directory[\\]](bold red)$nix_shell $character ";
    right_format = "$git_branch$git_status";
    continuation_prompt = "[∙](bright-black) ";

    character = {
      success_symbol = "[\\$](bold green)";
      error_symbol = "[\\$](bold red)";
      vimcmd_symbol = "[\\$](bold yellow)";
    };

    username = {
      disabled = false;
      show_always = true;
      style_user = "bold yellow";
      style_root = "bold red";
      format = "[$user]($style)";
    };
    hostname = {
      trim_at = ".";
      ssh_only = false;
      disabled = false;
      style = "bold blue";
      ssh_symbol = "🌐 ";
      format = "[$hostname]($style)";
    };

    directory = {
      truncation_length = 2;
      truncation_symbol = "…/";
      truncate_to_repo = false;
      style = "bold purple";
      format = "[$path]($style)[$read_only]($read_only_style)";
      repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style)";
      before_repo_root_style = "dimmed purple";
      repo_root_style = "bold purple";
      use_os_path_sep = true;
      use_logical_path = true;
      home_symbol = "~";
      read_only = " ";
      read_only_style = "bold red";
      disabled = false;
    };

    nix_shell = {
      # Nix shell names can be derivation-sized; state is the useful context.
      format = " [$symbol$state]($style)";
      symbol = "❄ ";
      style = "bold blue";
      impure_msg = "[impure](bold red)";
      pure_msg = "[pure](bold green)";
      unknown_msg = "[shell](bold yellow)";
      disabled = false;
    };

    git_branch = {
      symbol = " ";
      style = "bold green";
      format = "[$symbol$branch]($style) ";
      truncation_length = 24;
      truncation_symbol = "…";
    };

    git_status = {
      format = "([\\[$all_status$ahead_behind\\]]($style))";
      style = "bold red";
      conflicted = "=\${count}";
      ahead = "⇡\${count}";
      behind = "⇣\${count}";
      diverged = "⇡\${ahead_count}⇣\${behind_count}";
      untracked = "?\${count}";
      stashed = "*\${count}";
      modified = "!\${count}";
      staged = "+\${count}";
      renamed = "»\${count}";
      deleted = "✘\${count}";
      typechanged = "~\${count}";
    };
  };
}
