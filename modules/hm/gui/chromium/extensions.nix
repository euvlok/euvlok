{ config, lib }:
let
  catppuccinThemeIds = {
    frappe = "olhelnoplefjdmncknfphenjclimckaf";
    latte = "jhjnalhegpceacdhbplhnakmkdliaddd";
    macchiato = "cmpdlhmnmjhihmcfnigoememnffkimlk";
    mocha = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
  };
in
{
  chrome_store = [
    {
      id = "hlepfoohegkhhmjieoechaddaejaokhf";
      name = "Refined GitHub";
    }
    {
      id = "jinjaccalgkegednnccohejagnlnfdag";
      name = "Violentmonkey";
    }
    {
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      name = "Sponsor Block";
    }
    {
      id = "lmkeolibdeeglfglnncmfleojmakecjb";
      name = "YouTube No Translation";
    }
  ]
  ++ lib.lists.optional config.catppuccin.enable {
    id = "lnjaiaapbakfhlbjenjkhffcdpoompki";
    name = "Catppuccin for GitHub";
  }
  ++ lib.lists.optional (config.catppuccin.enable && config.catppuccin.chromium.enable) {
    id = catppuccinThemeIds.${config.catppuccin.chromium.flavor};
    name = "Catppuccin ${config.catppuccin.chromium.flavor} theme";
  };

  update_url = [
    {
      id = "lkbebcjgcmobigpeffafkodonchffocl";
      name = "Bypass Paywalls Chrome (BPC)";
      update_url = "https://gitflic.ru/project/magnolia1234/bpc_updates/blob/raw?file=updates.xml";
    }
  ];

  crx = [
    {
      id = "bolggfoncklhniejomgplkjcllmnonbh";
      name = "TWP - Translate Web Pages";
      version = "10.1.1.0";
      url = "https://github.com/FilipePS/Traduzir-paginas-web/releases/download/v10.1.1.0/TWP_10.1.1.0_Chromium.crx";
      sha256 = "sha256-X4m1To1n/1zQGrzQPXPyR8KIA4JleyyAh5AjuS2BvYw=";
    }
  ];

  zip = [
    {
      id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      name = "uBlock Origin";
      update_policy = "latest";
      repository = "gorhill/uBlock";
      asset_template = "uBlock0_{tag}.chromium.zip";
      archive_root = "uBlock0.chromium";
      load_unpacked = true;
    }
    {
      id = "lckanjgmijmafbedllaakclkaicjfmnk";
      name = "ClearURLs";
      update_policy = "pinned";
      version = "1.27.3";
      url = "https://github.com/ClearURLs/Addon/releases/download/1.27.3/ClearURLs.zip";
      sha256 = "sha256-LVyHnT59j1YrD/u0vVtKlIhO9ATY7VY3v02iYBVW0Ug=";
      load_unpacked = true;
    }
  ];
}
