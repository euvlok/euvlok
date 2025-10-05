#! /usr/bin/env nix-shell
#! nix-shell -i bash -p playerctl spotify --pure
# shellcheck shell=bash

players="spotify|rhythmbox"
if [ -z "$u" ]; then
    artist=$(playerctl -a metadata | grep -E $players | grep xesam:artist | cut -d " " -f 3-)
    song=$(playerctl -a metadata | grep -E $players | grep xesam:title | cut -d " " -f 3-)
    out="$artist - $song"
    out="${out##}"

    # This might seem redundant, but it actually removes extra whitespace from strings.
    out=$(echo $out | tr -s ' ')
    echo "$out"
else
    echo "No Player Found"
fi
