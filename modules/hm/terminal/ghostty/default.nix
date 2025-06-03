{
  pkgs,
  lib,
  config,
  osConfig,
  euvlok,
  ...
}:
let
  superKey = if osConfig.nixpkgs.hostPlatform.isLinux then "super" else "ctrl";
  inherit (euvlok)
    mkSuper
    mkSuperPerf
    mkSuperShift
    ;

  # Source: https://vt100.net/docs/vt100-ug/chapter3.html
  # Converter: https://www.rapidtables.com/convert/number/hex-to-octal.html
  ctrl =
    let
      x = "\\x";
    in
    {
      # SOH (Function Mnemonic): 001 -> "\x01"
      SOH = "${x}01"; # Start of heading
      ENQ = "${x}05"; # Enquiry
      ESC = "${x}1b"; # Escape

      # "2 ↓" physical keypad key:
      WORD_BACK = "${x}62"; # b
      # "6 →" physical keypad key:
      WORD_FORWARD = "${x}66"; # f
    };

  mkKeybindings = {
    cursor = [
      (mkSuper superKey "left" "text:${ctrl.SOH}")
      (mkSuper superKey "right" "text:${ctrl.ENQ}")
    ];

    screen = [
      (mkSuper superKey "k" "clear_screen")
      (mkSuper superKey "g" "write_screen_file:open")
      (mkSuperShift superKey "left" "scroll_page_up")
      (mkSuperShift superKey "right" "scroll_page_down")
    ];

    font = [
      (mkSuper superKey "0" "reset_font_size")
      (mkSuper superKey "equal" "increase_font_size:1")
      "${superKey}+shift+equal=increase_font_size:1"
      (mkSuper superKey "minus" "decrease_font_size:1")
      "${superKey}+shift+minus=decrease_font_size:1"
    ];

    clipboard = [
      (mkSuperPerf superKey "c" "copy_to_clipboard")
      (mkSuperPerf superKey "v" "paste_from_clipboard")
    ];

    misc = [
      (mkSuper superKey "a" "select_all")
      (mkSuper superKey "," "reload_config")
      (mkSuperShift superKey "backspace" "close_window")
    ];

    tabs = map (n: mkSuper superKey (toString n) "goto_tab:${toString n}") (lib.range 1 9);
  };

  # When altKeyBehavior is false the Alt mappings are omitted and the Ctrl keys are used
  # (to jump between words as in the default configuration). Otherwise
  # the Alt keys will jump between words and the Ctrl keys will jump to the start/end
  # of sentences (using placeholder commands "start_of_sentence" and "end_of_sentence").
  wordNavigation =
    if config.hm.ghostty.altKeyBehavior then
      [
        "alt+left=text:${ctrl.ESC}${ctrl.WORD_BACK}"
        "alt+right=text:${ctrl.ESC}${ctrl.WORD_FORWARD}"
      ]
    else
      [
        "ctrl+left=text:${ctrl.ESC}${ctrl.WORD_BACK}"
        "ctrl+right=text:${ctrl.ESC}${ctrl.WORD_FORWARD}"
      ];

  sentenceNavigation = lib.optionals config.hm.ghostty.altKeyBehavior [
    "ctrl+left=text:start_of_sentence"
    "ctrl+right=text:end_of_sentence"
  ];

  combinedCursor = lib.flatten [
    mkKeybindings.cursor
    wordNavigation
    sentenceNavigation
  ];
in
{
  options.hm.ghostty = {
    enable = lib.mkEnableOption "Ghostty";
    altKeyBehavior = lib.mkEnableOption "Make Alt jump between words and Ctrl jump to start/end of sentences";
  };

  config = lib.mkIf config.hm.ghostty.enable {
    programs.ghostty = {
      enable = true;
      package = if osConfig.nixpkgs.hostPlatform.isDarwin then null else pkgs.ghostty;
      settings = {
        ## Scroll
        scrollback-limit =
          let
            mkMillion = m: m * 1000000;
          in
          mkMillion 100;

        ## Mouse & Cursor
        cursor-style-blink = false;
        mouse-scroll-multiplier = 3;

        # Line height adjustment
        adjust-underline-position = 4;

        ## Keybinds
        keybind = combinedCursor ++ lib.flatten (lib.attrValues mkKeybindings);

        # Miscellaneous settings
        confirm-close-surface = false;
        quit-after-last-window-closed = true;
        clipboard-paste-protection = false;
      };
    };
  };
}
