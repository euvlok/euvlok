{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
{
  options.hm.chromium = {
    enable = lib.mkEnableOption "Chromium";
    browser = lib.mkOption {
      default = "chromium";
      description = "Select the Chromium browser variant";
      type = lib.types.enum [
        "brave"
        "chromium"
        "microsoft-edge"
        "ungoogled"
        "vivaldi"
      ];
    };
  };

  config = lib.mkIf config.hm.chromium.enable {
    assertions = [
      {
        assertion = osConfig.nixpkgs.hostPlatform.isLinux;
        message = "Chromium is only available on Linux";
      }
    ];
    programs.chromium = {
      enable = true;
      package =
        let
          browserPackages = {
            chromium = pkgs.chromium.override {
              enableWideVine = true;
            };
            ungoogled = pkgs.ungoogled-chromium;
            brave = pkgs.brave;
            vivaldi = pkgs.vivaldi;
          };
        in
        browserPackages.${config.hm.chromium.browser};
      dictionaries = builtins.attrValues {
        inherit (pkgs.hunspellDictsChromium)
          en_US
          de_DE
          fr_FR
          ;
      };
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
        { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
        { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
        { id = "lckanjgmijmafbedllaakclkaicjfmnk"; } # ClearURLs
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsor Block
        #TODO: preferably having bypass paywal by default
      ] ++ lib.optionals (config.catppuccin.enable) [ { id = "lnjaiaapbakfhlbjenjkhffcdpoompki"; } ];
      commandLineArgs = [
        # Debug
        "--enable-logging=stderr"

        # Web
        #! could cause issues in the future on darwin if there will be a chromium package
        "--ignore-gpu-blocklist"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"

        # Wayland
        "--ozone-platform-hint=wayland"
        "--enable-wayland-ime"
        "--wayland-text-input-version=3"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
      ];
    };
  };
}
