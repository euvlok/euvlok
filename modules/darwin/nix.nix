_: {
  # nix-daemon runs under launchd without a locale, so Perl-based
  # helpers in nixpkgs fetchers warn "Pathname can't be converted
  # from UTF-8 to current locale" for every non-ASCII path.
  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
}
