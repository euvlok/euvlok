{ lib, pkgs, ... }:
{
  programs.nix-ld = {
    enable = lib.modules.mkDefault true;
    libraries = lib.attrsets.attrValues {
      inherit (pkgs)
        # CLI runtimes and native language extensions
        glibc
        libffi
        libgcc
        ncurses
        readline
        sqlite
        libuuid
        libxcrypt
        # Older libcrypt.so.1 and libxml2.so.2 ABIs
        libxcrypt-legacy
        libxml2_13
        icu
        libunwind
        libedit
        gmp
        lz4
        brotli
        pcre2
        libidn2
        libssh2
        nghttp2
        c-ares
        krb5
        gnutls
        libgcrypt
        libgpg-error
        libcap

        # Browser and desktop dependencies, including optional dlopen libraries
        alsa-lib
        at-spi2-core
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        gtk4
        libcanberra-gtk3
        libdrm
        libgbm
        mesa
        libglvnd
        libnotify
        libpulseaudio
        libsecret
        libva
        libxcb
        libxkbcommon
        nspr
        nss
        pango
        pipewire
        vulkan-loader
        wayland
        libx11
        libxau
        libxcomposite
        libxcursor
        libxdamage
        libxdmcp
        libxext
        libxfixes
        libxft
        libxi
        libxinerama
        libxmu
        libxrandr
        libxrender
        libxscrnsaver
        libxt
        libxtst
        libxxf86vm
        libsm
        libice

        # ChatGPT's USB/HID and device-key addons
        libusb1
        hidapi
        tpm2-tss
        # Media codecs and game runtimes
        libjpeg
        libpng
        libtiff
        libwebp
        libavif
        librsvg
        libsndfile
        libopus
        flac
        libogg
        libvorbis
        libsamplerate
        openal
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        sdl3
        glfw3
        ;
      # Chromium and ChatGPT's optional Qt shims
      inherit (pkgs.qt5) qtbase;
      qt6-qtbase = pkgs.qt6.qtbase;
      inherit (pkgs.gst_all_1) gstreamer gst-plugins-base;
    };
  };
}
