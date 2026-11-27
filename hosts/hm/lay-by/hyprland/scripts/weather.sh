#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq curl cacert --pure
# shellcheck shell=bash

get_icon() {
  case $1 in
    # Icons for weather-icons
    01d | 01n) icon=" " ;;
    02d | 02n) icon=" " ;;
    03*) icon=" " ;;
    04*) icon=" " ;;
    09d | 09n) icon=" " ;;
    10d) icon=" " ;;
    10n) icon=" " ;;
    11d | 11n) icon=" " ;;
    13d | 13n) icon=" " ;;
    50d | 50n) icon=" " ;;
    *) icon="	" ;;

      # Icons for Font Awesome 5 Pro
      #01d) icon="";;
      #01n) icon="";;
      #02d) icon="";;
      #02n) icon="";;
      #03d) icon="";;
      #03n) icon="";;
      #04*) icon="";;
      #09*) icon="";;
      #10d) icon="";;
      #10n) icon="";;
      #11*) icon="";;
      #13*) icon="";;
      #50*) icon="";;
      #*) icon="";
  esac

  echo "$icon"
}

KEY="a78c793d7f2431574ca9c5f56e74fc9b"
CITY="4701458"
UNITS="imperial"
SYMBOL="°"

API="https://api.openweathermap.org/data/2.5"

if [ -n "$CITY" ]; then
  if [ "$CITY" -eq "$CITY" ] 2>/dev/null; then
    CITY_PARAM="id=$CITY"
  else
    CITY_PARAM="q=$CITY"
  fi

  weather=$(curl -sf "$API/weather?appid=$KEY&$CITY_PARAM&units=$UNITS")
else
  location=$(curl -sf https://location.services.mozilla.com/v1/geolocate?key=geoclue)

  if [ -n "$location" ]; then
    location_lat="$(jq '.location.lat' <<<"$location")"
    location_lon="$(jq '.location.lng' <<<"$location")"

    weather=$(curl -sf "$API/weather?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS")
  fi
fi

if [ -n "$weather" ]; then
  weather_desc=$(jq -r '.weather[0].description' <<<"$weather")
  weather_temp=$(jq '.main.temp' <<<"$weather" | cut -d "." -f 1)
  weather_icon=$(jq -r '.weather[0].icon' <<<"$weather")

  echo "$(get_icon "$weather_icon")" " $weather_desc", "$weather_temp$SYMBOL"
fi
