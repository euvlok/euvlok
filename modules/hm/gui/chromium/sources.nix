{
  browser = "chromium";
  extensions = [
    # --- From Chrome Web Store ---
    {
      id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      name = "uBlock Origin";
      source = "chrome-store";
    }
    {
      id = "hlepfoohegkhhmjieoechaddaejaokhf";
      name = "Refined GitHub";
      source = "chrome-store";
    }
    {
      id = "jinjaccalgkegednnccohejagnlnfdag";
      name = "Violentmonkey";
      source = "chrome-store";
    }
    {
      id = "lckanjgmijmafbedllaakclkaicjfmnk";
      name = "ClearURLs";
      source = "chrome-store";
    }
    {
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      name = "Sponsor Block";
      source = "chrome-store";
    }
    {
      id = "lmkeolibdeeglfglnncmfleojmakecjb";
      name = "YouTube No Translation";
      source = "chrome-store";
    }
    # --- From Third-Party Sources ---
    {
      id = "lkbebcjgcmobigpeffafkodonchffocl";
      name = "Bypass Paywalls Chrome (BPC)";
      source = "bpc";
    }
    {
      id = "kpaaapnegfaaoimjpagopchdbmenfngl";
      name = "TWP - Translate Web Pages";
      source = "url";
      url = "https://github.com/FilipePS/Traduzir-paginas-web/releases/download/v10.1.1.0/TWP_10.1.1.0_Chromium.crx";
    }
    {
      id = "lnjaiaapbakfhlbjenjkhffcdpoompki";
      name = "Catppuccin for GitHub";
      source = "chrome-store";
      condition = "config.catppuccin.enable";
    }
  ];
}
