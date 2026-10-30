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
        exec ${lib.meta.getExe config.programs.ssh.package} "$@"
      ''
    else
      lib.meta.getExe config.programs.ssh.package;
  workKey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_work";
  workIdentity = {
    name = "Maria Holovata";
    email = "m.holovata@ukrinfosystems.ua";
  };
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
  imports = [ ../../../modules/hm/cli/jujutsu.nix ];

  euvlok.home.jujutsu.enable = true;
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
            user = workIdentity // {
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
    jujutsu.settings = {
      user = {
        inherit (config.programs.git.settings.user) name email;
      };
      signing = {
        behavior = "own";
        backend = "gpg";
        key = config.programs.git.settings.user.signingkey;
      };
      git.colocate = true;
      "--scope" = [
        {
          "--when".repositories = [ "${config.home.homeDirectory}/Documents/work" ];
          user = workIdentity;
          signing = {
            backend = "ssh";
            key = workKey;
          };
        }
      ];
    };
    git-credential-oauth.enable = true;
  };
}
