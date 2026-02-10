#!/bin/bash

# Minimalist weather plugin for Sketchybar
# Format: current - min.max
# Uses wttr.in for IP-based location

# Get weather data
WEATHER_JSON=$(curl -s "wttr.in/?format=j1" 2>/dev/null)

if [ -z "$WEATHER_JSON" ]; then
    sketchybar --set "$NAME" label="-- - --.-"
    exit 0
fi

# Parse JSON - using more robust grep patterns
CURRENT_TEMP=$(echo "$WEATHER_JSON" | grep -o '"temp_C"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
MIN_TEMP=$(echo "$WEATHER_JSON" | grep -o '"mintempC"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
MAX_TEMP=$(echo "$WEATHER_JSON" | grep -o '"maxtempC"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')

# Check if we got valid data
if [ -z "$CURRENT_TEMP" ] || [ -z "$MIN_TEMP" ] || [ -z "$MAX_TEMP" ]; then
    sketchybar --set "$NAME" label="-.-.-"
    exit 0
fi

DISPLAY="${MIN_TEMP}.${CURRENT_TEMP}.${MAX_TEMP}"

# Update the bar item (no icon, just text)
sketchybar --set "$NAME" label="$DISPLAY"
