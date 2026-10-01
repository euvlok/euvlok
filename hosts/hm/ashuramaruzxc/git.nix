{
  config,
  lib,
  pkgs,
  ...
}:
let
  # GUI applications may inherit Apple's agent socket instead of Home Manager's.
  sshCommand =
    if pkgs.stdenv.hostPlatform.isDarwin then
      pkgs.writeShellScript "git-nix-ssh" ''
        if [ -z "$SSH_AUTH_SOCK" ] || [ -z "$SSH_CONNECTION" ]; then
          ${config.sshAuthSock.initialization.bash}
        fi
        exec ${lib.getExe config.programs.ssh.package} "$@"
      ''
    else
      lib.getExe config.programs.ssh.package;
  workKey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_work";
  # A separate SSH config prevents personal IdentityFile entries from accumulating.
  workSshConfig = pkgs.writeText "git-work-ssh-config" ''
    Host github.com
      HostName ssh.github.com
      Port 443
      User git

    Host *
      IdentityFile "${workKey}"
      IdentitiesOnly yes
  '';
in
{
  home.packages = [ pkgs.watchman ];

  programs = {
    gh.gitCredentialHelper.enable = true;
    gh.settings.git_protocol = "ssh";
    git = {
      enable = true;
      includes = [
        {
          condition = "gitdir:~/Documents/work/";
          contentSuffix = "work.gitconfig";
          contents = {
            user = {
              name = "Maria Holovata";
              email = ""; # Fill in the work email; do not inherit the personal email.
              signingKey = workKey;
              useConfigOnly = true;
            };
            gpg.format = "ssh";
            commit.gpgSign = true;
            core.sshCommand = "${sshCommand} -F ${workSshConfig}";
          };
        }
      ];
      settings = {
        core.sshCommand = "${sshCommand}";
        user = {
          name = "ashuramaruzxc";
          email = "ashuramaru@tenjin-dk.com";
          signingkey = "409D201E94508732A49ED0FC6BDAF874006808DF";
        };
        commit.gpgsign = true;
        gpg.format = "openpgp";
        filter.lfs = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
        alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
    git-credential-oauth.enable = true;
  };
}
