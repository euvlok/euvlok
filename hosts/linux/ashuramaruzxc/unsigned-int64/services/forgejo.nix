{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo;
  publicDomain = "git.tenjin-dk.com";
  httpPort = 3001;
  sshPort = 2222;
  redis = config.services.redis.servers.forgejo;
  redisUrl = database: "redis+socket://${redis.unixSocket}?db=${toString database}";
in
{
  imports = [
    ./forgejo/runner.nix
    ./forgejo/monitoring.nix
    ./forgejo/proxy.nix
  ];

  environment.systemPackages = [ cfg.package ];

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo-lts;
    useWizard = false;
    user = "forgejo";
    group = "forgejo";
    stateDir = "/var/lib/forgejo";
    customDir = "${cfg.stateDir}/custom";
    repositoryRoot = "${cfg.stateDir}/repositories";
    database = {
      type = "postgres";
      createDatabase = true;
      name = "forgejo";
      user = "forgejo";
      socket = "/run/postgresql";
      passwordFile = null;
    };
    lfs = {
      enable = true;
      contentDir = "${cfg.stateDir}/data/lfs";
    };
    settings = {
      DEFAULT = {
        APP_NAME = "Tenjin Forgejo";
        RUN_MODE = "prod";
      };
      server = {
        # Forgejo 15 derives WebAuthn's RP ID and origin from DOMAIN and ROOT_URL.
        DOMAIN = publicDomain;
        ROOT_URL = "https://${publicDomain}/";
        PROTOCOL = "http";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = httpPort;
        LOCAL_ROOT_URL = "http://127.0.0.1:${toString httpPort}/";
        # Forgejo authenticates uploaded account keys on its own Git-only port.
        DISABLE_SSH = false;
        START_SSH_SERVER = true;
        BUILTIN_SSH_SERVER_USER = "git";
        SSH_USER = "git";
        SSH_DOMAIN = publicDomain;
        SSH_PORT = sshPort;
        SSH_LISTEN_HOST = "::";
        SSH_LISTEN_PORT = sshPort;
        SSH_CREATE_AUTHORIZED_KEYS_FILE = false;
        OFFLINE_MODE = true;
        LANDING_PAGE = "login";
      };
      service = {
        REQUIRE_SIGNIN_VIEW = true;
        DISABLE_REGISTRATION = true;
        ALLOW_ONLY_EXTERNAL_REGISTRATION = false;
        SHOW_REGISTRATION_BUTTON = false;
        ENABLE_BASIC_AUTHENTICATION = true;
        ENABLE_REVERSE_PROXY_AUTHENTICATION = false;
        ENABLE_REVERSE_PROXY_AUTHENTICATION_API = false;
        ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = false;
        ENABLE_NOTIFY_MAIL = false;
        REGISTER_EMAIL_CONFIRM = false;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;
        DEFAULT_ALLOW_CREATE_ORGANIZATION = false;
        DEFAULT_USER_VISIBILITY = "limited";
        ALLOWED_USER_VISIBILITY_MODES = "limited,private";
        DEFAULT_ORG_VISIBILITY = "limited";
      };
      "service.explore" = {
        REQUIRE_SIGNIN_VIEW = true;
        DISABLE_USERS_PAGE = false;
        DISABLE_ORGANIZATIONS_PAGE = false;
        DISABLE_CODE_PAGE = false;
      };
      repository = {
        DEFAULT_PRIVATE = "private";
        FORCE_PRIVATE = true;
        DEFAULT_PUSH_CREATE_PRIVATE = true;
        ENABLE_PUSH_CREATE_USER = false;
        ENABLE_PUSH_CREATE_ORG = false;
        DISABLE_MIGRATIONS = false;
      };
      security = {
        INSTALL_LOCK = true;
        GLOBAL_TWO_FACTOR_REQUIREMENT = "all";
        PASSWORD_HASH_ALGO = "argon2";
        MIN_PASSWORD_LENGTH = 14;
        PASSWORD_COMPLEXITY = "off";
        DISABLE_QUERY_AUTH_TOKEN = true;
        DISABLE_GIT_HOOKS = true;
        IMPORT_LOCAL_PATHS = false;
        REVERSE_PROXY_LIMIT = 1;
        REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.1/32,::1/128";
      };
      session = {
        PROVIDER = "redis";
        PROVIDER_CONFIG = redisUrl 1;
        COOKIE_NAME = "forgejo_session";
        COOKIE_SECURE = true;
        SAME_SITE = "lax";
        SESSION_LIFE_TIME = 86400;
      };
      cache = {
        ADAPTER = "redis";
        HOST = redisUrl 0;
      };
      queue = {
        TYPE = "redis";
        CONN_STR = redisUrl 2;
      };
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "https://data.forgejo.org";
      };
      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };
      oauth2.ENABLED = false;
      api.ENABLE_SWAGGER = false;
      mailer = {
        ENABLED = true;
        PROTOCOL = "sendmail";
        FROM = config.programs.msmtp.accounts.default.from;
        SENDMAIL_PATH = lib.getExe' pkgs.system-sendmail "sendmail";
        SENDMAIL_ARGS = "--";
      };
      federation.ENABLED = false;
      packages.ENABLED = false;
      "other" = {
        SHOW_FOOTER_VERSION = false;
        SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
        ENABLE_SITEMAP = false;
        ENABLE_FEED = false;
      };
      log = {
        MODE = "console";
        LEVEL = "Info";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ sshPort ];

  # A dedicated, permission-controlled socket isolates sessions and queues from
  # other applications without putting a Redis password in the Nix store.
  services.redis.servers.forgejo = {
    enable = true;
    bind = "127.0.0.1";
    port = 0;
    openFirewall = false;
    unixSocket = "/run/redis-forgejo/redis.sock";
    unixSocketPerm = 660;
    appendOnly = true;
    settings = {
      appendfsync = "everysec";
      maxmemory-policy = "noeviction";
    };
  };
  users.users.forgejo.extraGroups = [ redis.user ];
  systemd.services.forgejo = {
    after = [ "redis-forgejo.service" ];
    requires = [ "redis-forgejo.service" ];
  };
  services.postgresqlBackup.databases = [ cfg.database.name ];

  # Keep signing keys, including the TOTP encryption key, with the data and database.
  services.forgejo.dump = {
    enable = true;
    interval = "daily";
    backupDir = "/var/lib/backup/forgejo";
    type = "tar.zst";
    age = "7d";
  };
}
