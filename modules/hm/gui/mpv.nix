{ lib, config, ... }:
{
  options.hm.mpv.enable = lib.mkEnableOption "MPV";

  config = lib.mkIf config.hm.mpv.enable {
    programs.mpv.enable = true;
    programs.mpv.config = {
      screenshot-directory = "~/Pictures/mpv_screenshots";
      screenshot-format = "png";
      screenshot-template = "%F_%p";

      cache-secs = 3 * 100; # Cache duration in seconds
      demuxer-readahead-secs = 30; # Read 30 seconds ahead
      cache-pause = "yes";

      ytdl-format = "bestvideo[height<=?1080]+bestaudio/best";
      ytdl = "yes";

      # Video Settings
      interpolation = "no"; # No frame interpolation, keep it real
      deinterlace = "no"; # No deinterlacing, keep them lines
      hwdec = "no"; # No hardware decoding, let the CPU handle it for accuracy
      loop-file = "inf";
      loop-playlist = "inf";

      # Audio Settings
      audio-pitch-correction = "no";
      audio-delay = 0;

      keep-open = "yes"; # Don't close video when it finishes
    };
  };
}
