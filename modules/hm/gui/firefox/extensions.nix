{ buildFirefoxXpiAddon }:
{
  "clearurls" = buildFirefoxXpiAddon {
    pname = "clearurls";
    version = "1.28.0";
    addonId = "{74145f27-f039-47ce-a470-a662b129930a}";
    url = "https://addons.mozilla.org/firefox/downloads/file/5286652/clearurls-1.28.0.xpi";
    sha256 = "sha256-aTYBuh8hxpQDdPdqzC3UvTIBhpsP4QqxuSe1k+4lCNE=";
  };
  "magnolia@12.34" = buildFirefoxXpiAddon {
    pname = "magnolia@12.34";
    version = "4.5.0.0";
    addonId = "magnolia@12.34";
    url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-4.5.0.0.xpi";
    sha256 = "sha256-hUNpZqqK5PBMPax/GFih79nYI9a+t5QNwQ/RxRsZ2FM=";
  };
  "refined-github-" = buildFirefoxXpiAddon {
    pname = "refined-github-";
    version = "26.11.6";
    addonId = "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}";
    url = "https://addons.mozilla.org/firefox/downloads/file/5216077/refined_github-26.11.6.xpi";
    sha256 = "sha256-h3KG6ANOhounmzJRldvX3eqXJtyzJlaPHGVtBXroP/8=";
  };
  "sponsorblock" = buildFirefoxXpiAddon {
    pname = "sponsorblock";
    version = "6.1.7";
    addonId = "sponsorBlocker@ajay.app";
    url = "https://addons.mozilla.org/firefox/downloads/file/4897574/sponsorblock-6.1.7.xpi";
    sha256 = "sha256-DVDhYyxvFe4VpUPmcOHFcpdGBaXAJiKRbgjgJoA9+D8=";
  };
  "ublock-origin" = buildFirefoxXpiAddon {
    pname = "ublock-origin";
    version = "1.77.0";
    addonId = "uBlock0@raymondhill.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/5290541/ublock_origin-1.77.0.xpi";
    sha256 = "sha256-iU6kje3SamN6uYumJ65wt+2UeY6r/UsIn15ec1JKJOs=";
  };
  "violentmonkey" = buildFirefoxXpiAddon {
    pname = "violentmonkey";
    version = "2.50.0";
    addonId = "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}";
    url = "https://addons.mozilla.org/firefox/downloads/file/5170937/violentmonkey-2.50.0.xpi";
    sha256 = "sha256-XgdEZcf90xk05bRmTj0urFQmnfV1oMDbUshD/pr9gd8=";
  };
}
