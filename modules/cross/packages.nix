{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    # Media
    inherit (pkgs)
      ffmpeg-full
      # ffmpegthumbs
      imagemagick
      yt-dlp
      ;

    # # Networking
    # inherit (pkgs)
    #   bsd-finger
    #   ;

    # Basic Utils
    inherit (pkgs)
      btop
      curl
      dig
      htop
      jq
      lz4
      ncdu
      nmap
      p7zip
      # pavucontrol
      rar
      tldr
      tree
      unzip
      wget
      wl-clipboard
      xclip
      zip
      ;

    # Rust Tools
    inherit (pkgs)
      duf # df
      dust # du
      eza # ls
      fd # find
      hyperfine # bash/zsh time
      procs # ps
      ripgrep # grep
      sd # sed
      tokei # cloc
      ;
  };
}
