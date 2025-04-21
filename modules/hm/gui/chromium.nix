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
            chromium = pkgs.chromium;
            ungoogled = pkgs.ungoogled-chromium;
            brave = pkgs.brave;
            vivaldi = pkgs.vivaldi;
          };
        in
        browserPackages.${config.hm.chromium.browser};
      #TODO: add more dictionaries
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      extensions = [
        { id = "lckanjgmijmafbedllaakclkaicjfmnk"; } # ClearURLs
        { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return YT Dislikes
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
        { id = "jinjaccalgkegednnccohejagnlnfdag"; } # Violentmonkey
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
