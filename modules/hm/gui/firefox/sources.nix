{
  browser = "firefox";
  extensions = [
    # --- From Mozilla Add-ons (AMO) ---
    {
      id = "ublock-origin";
      name = "uBlock Origin";
      source = "amo";
    }
    {
      id = "refined-github-";
      name = "Refined GitHub";
      source = "amo";
    }
    {
      id = "violentmonkey";
      name = "Violentmonkey";
      source = "amo";
    }
    {
      id = "clearurls";
      name = "ClearURLs";
      source = "amo";
    }
    {
      id = "sponsorblock";
      name = "SponsorBlock";
      source = "amo";
    }
    # --- From Third-Party Sources ---
    {
      id = "magnolia@12.34";
      name = "Bypass Paywalls Clean";
      source = "bpc";
    }
  ];
}
