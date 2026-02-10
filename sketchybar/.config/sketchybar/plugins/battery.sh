#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

# Check if on AC power and fully charged
if [[ "$CHARGING" != "" ]] && [ "$PERCENTAGE" = "100" ]; then
  # Just show "AC" when fully charged on power
  sketchybar --set "$NAME" label="AC"
elif [[ "$CHARGING" != "" ]]; then
  # Show "AC" + percentage when charging but not full
  sketchybar --set "$NAME" label="AC${PERCENTAGE}%"
else
  # Show "BT" + percentage when on battery
  sketchybar --set "$NAME" label="BT${PERCENTAGE}%"
fi
