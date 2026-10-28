{ euvlokInputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager;
  hm = euvlokInputs.home-manager;
  hmLib = import "${hm}/modules/lib/stdlib-extended.nix" lib;
  option =
    type: default: description:
    lib.options.mkOption { inherit type default description; };
  userType = lib.types.submoduleWith {
    class = "homeManager";
    specialArgs = {
      lib = hmLib;
      osConfig = config;
      darwinConfig = config;
      osClass = "darwin";
      modulesPath = "${hm}/modules";
    }
    // cfg.extraSpecialArgs;
    modules = [
      ({ name, ... }: {
        imports =
          (import "${hm}/modules/modules.nix" {
            inherit pkgs;
            lib = hmLib;
            useNixpkgsModule = !cfg.useGlobalPkgs;
          })
          ++ cfg.sharedModules;
        submoduleSupport = {
          enable = true;
          externalPackageInstall = cfg.useUserPackages;
        };
        home = {
          username = config.users.users.${name}.name;
          homeDirectory = config.users.users.${name}.home;
        };
        home.sessionVariables = lib.attrsets.optionalAttrs (config.environment.variables ? NIX_PATH) {
          inherit (config.environment.variables) NIX_PATH;
        };
        nix.enable = false;
      })
    ];
  };
  activate =
    name: user:
    let
      script = pkgs.writeShellScript "home-manager-${name}" ''
        ${lib.strings.optionalString (
          cfg.backupFileExtension != null
        ) "export HOME_MANAGER_BACKUP_EXT=${lib.strings.escapeShellArg cfg.backupFileExtension}"}
        ${lib.strings.optionalString (
          cfg.backupCommand != null
        ) "export HOME_MANAGER_BACKUP_COMMAND=${lib.strings.escapeShellArg cfg.backupCommand}"}
        ${lib.strings.optionalString cfg.overwriteBackup "export HOME_MANAGER_BACKUP_OVERWRITE=1"}
        ${lib.strings.optionalString cfg.verbose "export VERBOSE=1"}
        exec ${user.home.activationPackage}/activate --driver-version 1 >&2
      '';
    in
    ''
      printf >&2 'Activating Home Manager for %s\n' ${lib.strings.escapeShellArg name}
      /bin/launchctl asuser "$(/usr/bin/id -u ${lib.strings.escapeShellArg name})" \
        /usr/bin/sudo -u ${lib.strings.escapeShellArg name} --set-home ${script}
    '';
in
{
  options.home-manager = {
    useGlobalPkgs = lib.options.mkEnableOption "the system package set for Home Manager";
    useUserPackages = lib.options.mkEnableOption "user profile installation through ndw";
    backupFileExtension =
      option (lib.types.nullOr lib.types.str) null
        "Backup extension for existing home files";
    backupCommand = option (lib.types.nullOr (
      lib.types.either lib.types.str lib.types.path
    )) null "Command used to back up existing home files";
    overwriteBackup = lib.options.mkEnableOption "overwriting existing Home Manager backups";
    verbose = lib.options.mkEnableOption "verbose Home Manager activation";
    extraSpecialArgs = option lib.types.attrs { } "Extra Home Manager module arguments";
    sharedModules =
      option (lib.types.listOf lib.types.raw) [ ]
        "Modules shared by all Home Manager users";
    users = option (lib.types.attrsOf userType) { } "Home Manager configurations";
  };

  config = lib.modules.mkIf (cfg.users != { }) {
    warnings = lib.lists.concatMap (user: user.warnings) (builtins.attrValues cfg.users);
    assertions = lib.lists.concatLists (
      lib.attrsets.mapAttrsToList (
        name: user:
        map (assertion: {
          inherit (assertion) assertion;
          message = "${name}: ${assertion.message}";
        }) user.assertions
      ) cfg.users
    );
    users.users = lib.modules.mkIf cfg.useUserPackages (
      lib.attrsets.mapAttrs (_: user: { packages = [ user.home.path ]; }) cfg.users
    );
    environment.paths.link = lib.lists.optional cfg.useUserPackages "/etc/profile.d";
    system.activation.steps.home-manager = {
      deps = [
        "users"
        "launchd"
      ];
      text = lib.strings.concatStringsSep "\n" (lib.attrsets.mapAttrsToList activate cfg.users);
    };
  };
}
