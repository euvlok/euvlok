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
      version = "10.2.1.0";
      url = "https://github.com/FilipePS/Traduzir-paginas-web/releases/download/v10.2.1.0/TWP_10.2.1.0_Chromium_MV2_deprecated.crx";
      sha256 = "sha256-uy6d7irHQUwYBP8I/X30ISPnZ5KhUQfFM9XuELa32jI=";
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
      version = "1.28.0";
      url = "https://gitlab.com/ClearURLs/ClearUrls/-/jobs/18247859715/artifacts/raw/ClearURLs.zip";
      sha256 = "sha256-nHOqiQRo301HRh9TUWwLpQQOaT5FqqAglwDSRIQacGE=";
      load_unpacked = true;
    }
  ];
}
