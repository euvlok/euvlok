{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sops;
  source = "${euvlokInputs.sops-nix}/modules/nix-darwin";
  # Reuse SOPS declarations, validation, and manifests, not its OS hooks
  upstream = import "${source}/default.nix" { inherit config lib pkgs; };
  manifestFor = pkgs.callPackage "${source}/manifest-for.nix" { inherit cfg; };
  regular = lib.attrsets.filterAttrs (_: secret: !secret.neededForUsers) cfg.secrets;
  early = lib.attrsets.filterAttrs (_: secret: secret.neededForUsers) cfg.secrets;
  manifest = manifestFor "" regular cfg.templates { };
  earlyManifest = manifestFor "-for-users" early { } {
    secretsMountPoint = "/run/secrets-for-users.d";
    symlinkPath = "/run/secrets-for-users";
  };
  withEnvironment = import "${source}/with-environment.nix" { inherit cfg lib; };
  keygen = lib.strings.optionalString cfg.age.generateKey ''
    if [[ ! -f ${lib.strings.escapeShellArg cfg.age.keyFile} ]]; then
      mkdir -p "$(dirname ${lib.strings.escapeShellArg cfg.age.keyFile})"
      ${lib.meta.getExe' pkgs.age "age-keygen"} -o ${lib.strings.escapeShellArg cfg.age.keyFile}
    fi
  '';
  install =
    extra: manifest:
    keygen + withEnvironment "${cfg.package}/bin/sops-install-secrets ${extra} ${manifest}";
  hasSecrets = cfg.secrets != { } || cfg.templates != { };
in
{
  inherit (upstream) options;
  imports = [ "${source}/templates" ];

  config = lib.modules.mkMerge [
    {
      sops.age.keyFile = lib.modules.mkDefault "/var/lib/sops/age/keys.txt";
      sops.age.sshKeyPaths = lib.modules.mkDefault [ ];
      sops.environment.SOPS_GPG_EXEC = lib.modules.mkIf (
        cfg.gnupg.home != null || cfg.gnupg.sshKeyPaths != [ ]
      ) (lib.modules.mkDefault "${cfg.gnupg.package}/bin/gpg");
      sops.environment.PATH = lib.modules.mkIf (cfg.age.plugins != [ ]) (
        lib.strings.makeBinPath cfg.age.plugins
      );
    }
    (lib.modules.mkIf hasSecrets {
      assertions = [
        {
          assertion =
            cfg.gnupg.home != null
            || cfg.gnupg.sshKeyPaths != [ ]
            || cfg.age.keyFile != null
            || cfg.age.sshKeyPaths != [ ];
          message = "SOPS requires a GPG or age key source";
        }
        {
          assertion = !(cfg.gnupg.home != null && cfg.gnupg.sshKeyPaths != [ ]);
          message = "SOPS cannot combine gnupg.home with gnupg.sshKeyPaths";
        }
        {
          assertion = lib.lists.all (
            secret:
            (secret.uid == 0 || secret.owner == null)
            && (secret.gid == 0 || secret.group == null)
            && (
              !secret.neededForUsers
              || ((secret.uid == 0 || secret.owner == "root") && (secret.gid == 0 || secret.group == "root"))
            )
          ) (builtins.attrValues cfg.secrets);
          message = "SOPS ownership must use either names or IDs, and early secrets must be root-owned";
        }
      ];
      system.build.sops-nix-manifest = manifest;
      system.activation.steps.sops = {
        deps = [ "users" ];
        text = install "" manifest;
      };
      system.activation.steps.launchd.deps = [ "sops" ];
      launchd.daemons.sops-install-secrets = {
        enable = true;
        script = install "" manifest;
        config = {
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    })
    (lib.modules.mkIf (early != { }) {
      system.build.sops-nix-users-manifest = earlyManifest;
      system.activation.steps.sops-for-users = {
        deps = [ "files" ];
        text = install "-ignore-passwd" earlyManifest;
      };
      system.activation.steps.users.deps = [ "sops-for-users" ];
      launchd.daemons.sops-install-secrets-for-users = {
        enable = true;
        script = install "-ignore-passwd" earlyManifest;
        config = {
          RunAtLoad = true;
          KeepAlive = false;
        };
      };
    })
  ];
}
