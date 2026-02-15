{ lib, pkgs, ... }:
{
  systemd.services.slskdl = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = builtins.attrValues { inherit (pkgs.eupkgs) yt-dlp; };

    # I literally couldn't give less of a fuck if you login to my soulseek
    # account. Don't @ me about having a plaintext password on github
    serviceConfig = {
      Type = "simple";
      ExecStart =
        "${lib.getExe pkgs.slsk-batchdl} "
        + "--user autosyncdl "
        + "--pass 'tn8vM%Ua@$VD' "
        + "-p /media/HDD/spotmusic "
        + "--yt-dlp --pref-max-bitrate 9000 "
        + "--min-bitrate 128 https://open.spotify.com/playlist/3wXqYceDHpxJVKkszHWBii";
    };
  };

  systemd.timers.slskdl = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "60s";
      OnUnitActiveSec = "6h";
      Persistent = true;
    };
  };
}
