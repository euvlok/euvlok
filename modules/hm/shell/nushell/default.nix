{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  jj-completions = pkgs.runCommand "jj-completions.nu" {
    buildInputs = builtins.attrValues { inherit (pkgs.unstable) jujutsu; };
  } ''jj util completion nushell > "$out"'';
  atuin-completions = pkgs.runCommand "atuin-completions.nu" {
    buildInputs = builtins.attrValues { inherit (pkgs.unstable) atuin; };
  } ''atuin gen-completions -s nushell > "$out"'';
  paths = import ../paths.nix { inherit lib; };
in
{
  options.hm.nushell.enable = lib.mkEnableOption "Nushell";

  config = lib.mkIf config.hm.nushell.enable {
    programs.nushell = {
      enable = true;
      package = pkgs.unstable.nushell;
      shellAliases = {
        # CD
        cd = "__zoxide_z";
        dc = "__zoxide_z";

        # List Files
        lt = "ls --all | sort-by size | reverse";
        ll = "ls --all";
        llf = "ls --all | where type == file;";
        ld = ''ls --all | where name =~ "^\\."'';

        # Time
        nowtime = "date now";

        # File Operations
        mv = "mv -iv";
        cp = "cp -iv";
        rm = "rm -v";
        mkdir = "mkdir -v";
        untar = "tar -zxvf";
        targz = "tar -cvzf";

        # Video
        m4a = "yt-dlp-script m4a";
        "m4a-cut" = "yt-dlp-script m4a-cut";
        mp3 = "yt-dlp-script mp3";
        "mp3-cut" = "yt-dlp-script mp3-cut";
        mp4 = "yt-dlp-script mp4";
        "mp4-cut" = "yt-dlp-script mp4-cut";

        # Misc
        myip = "http get 'https://ipinfo.io/ip'";
        path = "echo $env.PATH";

        rebuild =
          if pkgs.stdenvNoCC.isLinux then
            "nixos-rebuild switch --flake (readlink -f /etc/nixos) --use-remote-sudo"
          else
            "sudo nix-darwin switch --flake (readlink -f /etc/nixos)";
      };

      configFile.text = builtins.readFile ./config.nu;

      extraConfig =
        let
          customCompletions = pkgs.fetchFromGitHub {
            owner = "nushell";
            repo = "nu_scripts";
            rev = "b2d512f6c67f68895a26136c6ce552281efbec6e";
            hash = "sha256-iC5Qmyn9vDr4b1BWtJkC3pl2dOam2Se51+ENvRdXlvA=";
          };
          completionTypes =
            let
              enableComp = n: lib.optionals config.programs.${n}.enable [ n ];
            in
            [
              "bat"
              "curl"
              "man"
              "nix"
              "rg"
            ]
            ++ enableComp "git"
            ++ enableComp "ssh"
            ++ enableComp "vscode"
            ++ enableComp "zellij"
            ++ enableComp "zoxide";

          sourceCommands = map (
            t: "source ${customCompletions}/custom-completions/${t}/${t}-completions.nu"
          ) completionTypes;
        in
        ''
          ${paths.hm.shell.binPaths.nushell}
          ${builtins.concatStringsSep "\n" sourceCommands}
          ${builtins.readFile ./aliases.nu}
          ${lib.optionalString config.programs.jujutsu.enable "source ${jj-completions}"}
          ${lib.optionalString config.programs.atuin.enable "source ${atuin-completions}"}
        '';
    };
  };
}
