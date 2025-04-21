{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    # mail client
    inherit (pkgs) thunderbird; # it works on macos now
    # Media
    inherit (pkgs)
      ffmpeg-full
      # ffmpegthumbs #! this is supposed to be kdePackages
      imagemagick
      yt-dlp
      ;

    # Networking
    inherit (pkgs)
    /** #! only for linux
    #TODO: separate these packages from macos
    bsd-finger 
    bsd-fingerd 
     */
      dig
      curl
      nmap
    ;
    # Archive utils
    inherit (pkgs)
      p7zip
      lz4
      rar
      zip
      unzip
      zstd
      gzip
    ;
    # Basic Utils
    inherit (pkgs)
      btop
      htop
      jq
      ncdu
      tldr
      tree
      wget
      wl-clipboard
      xclip
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
