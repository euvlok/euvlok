{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../../modules/scripts/yt-dlp-script.sh)
  );
in
{
  options.hm.nushell.enable = lib.mkEnableOption "Nushell";

  config = lib.mkIf config.hm.nushell.enable {
    programs.nushell = {
      enable = true;
      package =
        inputs.nixpkgs-unstable-small.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}.nushell;
      plugins = builtins.attrValues { inherit (pkgs.nushellPlugins) formats highlight query; };
      shellAliases = {
        # CD
        cd = "z";
        dc = "z";

        # List Files
        lt = "ls --all | sort-by size -r";
        ll = "ls --all";
        llf = ''ls --all | where type == "file"'';
        ld = ''ls --all | find --regex "^\\."'';

        # Time
        now = ''date now | format date "%H:%M:%S"'';
        nowtime = "date now";
        nowdate = ''date now | format date "%d-%m-%Y"'';
        nowunix = "date now | format date '%s'";

        # File Operations
        mv = "mv -iv";
        cp = "cp -iv";
        rm = "rm -v";
        mkdir = "mkdir -v";
        untar = "tar -zxvf";
        targz = "tar -cvzf";

        # Video
        m4a = "${yt-dlp-script} m4a";
        m4a-cut = "${yt-dlp-script} m4a-cut";
        mp3 = "${yt-dlp-script} mp3";
        mp3-cut = "${yt-dlp-script} mp3-cut";
        mp4 = "${yt-dlp-script} mp4";
        mp4-cut = "${yt-dlp-script} mp4-cut";

        # Misc
        myip = "http get 'https://ipinfo.io/ip'";
        mount = ''df -h | str replace "Mounted on" Mounted_On | detect columns'';
        xdg-data-dirs = ''echo $env.XDG_DATA_DIRS | str replace -a ":" "\n" | lines | enumerate'';
        path = ''echo $env.PATH'';

        rebuild = if osConfig.nixpkgs.hostPlatform.isLinux then "nh os switch" else "nh darwin switch";
      };

      configFile.text = ''
        let $config = {
          rm_always_trash: true
          shell_integration: true
          highlight_resolved_externals: true
          use_kitty_protocol: true
          completion_algorithm: "fuzzy"
        }
      '';

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
        builtins.concatStringsSep "\n" sourceCommands
        + "\n"
        + ''
          def nix-build-file [
              file: string,
              args: string = "{}"
          ] {
              nix-build -E $"with import <nixpkgs> {}; callPackage ./$file $args"
          }
        ''
        + ''
          def update [] {
              let nix_user = (whoami)
              let raw_host = (hostname)
              let is_darwin = (sys host | get name | str downcase | str contains "darwin")
              let nix_host = if $is_darwin {
                  # Only strip .local if present on macOS
                  $raw_host | str replace -r '\.local$' \'\'
              } else {
                  $raw_host
              }
              let flake_path = "/etc/nixos"
              let flake_eval_path = "/etc/nixos"
              let flake_attr = if $is_darwin {
                  "darwinConfigurations"
              } else {
                  "nixosConfigurations"
              }
              let nix_user_escaped = ($nix_user | str replace '"' '\\"')
              let nix_host_escaped = ($nix_host | str replace '"' '\\"')
              let github_username = (
                  nix eval --raw --impure --expr (
                      'let
                        flake = builtins.getFlake "' + $flake_eval_path + '";
                        host = flake.' + $flake_attr + '."' + $nix_host_escaped + '";
                        user = "' + $nix_user_escaped + '";
                      in
                        host.config.home-manager.users.''${user}.programs.git.userName'
                  ) | str downcase | str trim
              )
              let matching_inputs = (
                  nix eval --json --impure --expr (
                      '(builtins.attrNames (builtins.getFlake "' + $flake_eval_path + '").inputs)'
                  )
                  | from json
                  | filter {|x| $x | str ends-with ("-" + $github_username)}
                  | str join " "
              )
              nix flake update $matching_inputs --flake $flake_path
          }
        '';
    };
  };
}
