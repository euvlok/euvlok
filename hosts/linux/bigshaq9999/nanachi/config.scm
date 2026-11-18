(defsrc
  ;; Define all physical keys we intend to intercept and manage.
  ;; Order matters for deflayer mapping!
  ;; 1    2     3   4   5   6   7   8   9   10  11  12  13
  esc    caps  a   s   d   f   e   h   j   k   l   ;   o
)

(defvar
  tap-time 100
  hold-time 120
  arrow-hold-time 300 ;; 3 seconds in milliseconds
  toggle-hold-time 5000 ;; 10 seconds in milliseconds

  ;; Keys that trigger an early tap decision for left-hand mods
  left-hand-keys (
    a s d f g q w e r t z x c v b
  )
  ;; Keys that trigger an early tap decision for right-hand mods (used by l, ;)
  right-hand-keys (
     h j k l ; y u i o p n m , . /
  )
)

;; Layers
(deflayer base
  ;; Default active layer with home row mods active.
  ;; 'e' key uses the '@e-conditional-arrows' alias.
  ;; defsrc: esc    caps  a   s   d   f   e                      h   @j  @k  @l  @;  @o-mods-on
  caps   esc   a   s   d   f  e   h   j   k   l   ;   @o-mods-off
)

(deflayer base-no-mods
  ;; Layer active when home row mods are toggled OFF.
  ;; 'e' key uses the same '@e-conditional-arrows' alias.
  ;; defsrc: esc    caps  a   s   d   f   e                      h   j   k   l   ;   @o-mods-off
  caps   esc   @a  @s  @d  @f  @e-conditional-arrows  h   @j  @k  @l  @;  @o-mods-on
)

(deflayer arrow-layer
  ;; Temporarily active while 'e' is held.
  ;; defsrc: esc    caps  a   s   d   f   e   h     j     k   l     ;   o
  ;; arrow:  _      _     _   _   _   _   _   left  down  up  right _   _
     _      _     _   _   _   _   _   _   left  down  up  right _
)

;; Aliases
(defalias
  ;; Home Row Mod Definitions

  ;; Left Hand (using tap-hold-release-keys)
  a (tap-hold-release-keys $tap-time $hold-time a lmet $left-hand-keys)
  s (tap-hold-release-keys $tap-time $hold-time s lalt $left-hand-keys)
  d (tap-hold-release-keys $tap-time $hold-time d lctl $left-hand-keys)
  f (tap-hold-release-keys $tap-time $hold-time f lsft $left-hand-keys)

  ;; Right Hand (j, k simplified to basic tap-hold for robustness)
  j (tap-hold $tap-time $hold-time j rsft) ;; Tap 'j', Hold Right Shift
  k (tap-hold $tap-time $hold-time k rctl) ;; Tap 'k', Hold Right Ctrl
  l (tap-hold-release-keys $tap-time $hold-time l ralt $right-hand-keys) ;; Tap 'l', Hold Right Alt
  ; (tap-hold-release-keys $tap-time $hold-time ; rmet $right-hand-keys) ;; Tap ';', Hold Right Meta

  ;; 'e' Key Arrow Layer Definition
  ;; This defines the standard behavior (tap 'e', hold 3s for arrows) used in the 'switch' default case
  e-normal-tap-hold (tap-hold $tap-time $arrow-hold-time e (layer-while-held arrow-layer))

  ;; Alias containing the switch logic for 'e'
  e-conditional-arrows (switch
     (lctl) (layer-while-held arrow-layer) break ;; If lctl (from holding 'd') is active, INSTANT arrow layer
     ()     @e-normal-tap-hold            break ;; Otherwise (lctl not held), use normal tap/3s-hold behavior
   )

  ;; 'o' Key Toggle Definitions (standard tap-hold)
  ;; Tap 'o', Hold 10s -> Switch to base-no-mods (turn mods OFF)
  o-mods-on (tap-hold $tap-time $toggle-hold-time o (layer-switch base-no-mods))
  ;; Tap 'o', Hold 10s -> Switch back to base (turn mods ON)
  o-mods-off (tap-hold $tap-time $toggle-hold-time o (layer-switch base))
)
