{ pkgs, ... }:
{
  programs.chromium = {
    extensions =
      let
        bpc-version = "3.9.1.2";
        bpc-src = pkgs.fetchurl {
          url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass-paywalls-chrome-clean-${bpc-version}.crx";
          sha256 = "sha256-KvHSxP4zC+VvYoGFyz2b2e8CDlu0N/ujiq99LVdpr3E=";
        };
      in
      [
        # necessity
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
        { id = "cdglnehniifkbagbbombnjghhcihifij"; } # kagi search
        { id = "hkligngkgcpcolhcnkgccglchdafcnao"; } # web archives

        # devtools
        { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # react devtools
        { id = "lmhkpmbekcpmknklioeibfkpmmfibljd"; } # redux devtools
        { id = "nhdogjmejiglipccpnnnanhbledajbpd"; } # vuejs devtools
        { id = "ienfalfjdbdpebioblfackkekamfmbnh"; } # angular
        { id = "kmcfjchnmmaeeagadbhoofajiopoceel"; } # solidjs
        { id = "bhchdcejhohfmigjafbampogmaanbfkg"; } # user agent

        { id = "hkgfoiooedgoejojocmhlaklaeopbecg"; } # Picture in Picture
        { id = "hipekcciheckooncpjeljhnekcoolahp"; } # tabliss
        { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # stylus
        { id = "gcknhkkoolaabfmlnjonogaaifnjlfnp"; } # foxyproxy
        { id = "oboonakemofpalcgghocfoadofidjkkk"; } # keepassxc
        { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
        { id = "kbmfpngjjgdllneeigpgjifpgocmfgmb"; } # reddit enhancment
        { id = "dneaehbmnbhcippjikoajpoabadpodje"; } # old reddit
        { id = "cnojnbdhbhnkbcieeekonklommdnndci"; } # search by image
        { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; } # google translate
        { id = "jgejdcdoeeabklepnkdbglgccjpdgpmf"; } # old twitter layout
        {
          id = "lkbebcjgcmobigpeffafkodonchffocl";
          version = bpc-version;
          crxPath = bpc-src;
        }
      ];
  };
}
