#!/bin/sh

# Event-driven keyboard layout indicator for Sketchybar
# This version responds to input source change events

# Get the current input source
# Try multiple methods to get the layout
if command -v swift &> /dev/null; then
    # Use swift to get current input source (most reliable)
    INPUT_SOURCE=$(swift - <<'EOF' 2>/dev/null
import Carbon
let inputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
let layoutName = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
let name = Unmanaged<CFString>.fromOpaque(layoutName!).takeUnretainedValue() as String
print(name)
EOF
)
else
    # Fallback to defaults read
    INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -A 1 "KeyboardLayout Name" | tail -n 1 | cut -d '"' -f 2)
fi

# Map layout names to short codes
case "$INPUT_SOURCE" in
    *"U.S."*|*"US"*|*"ABC"*|*"com.apple.keylayout.US"*)
        LAYOUT="US"
        ;;
    *"Colemak"*|*"colemak"*)
        LAYOUT="CM"
        ;;
    *"Dvorak"*)
        LAYOUT="DV"
        ;;
    *"British"*|*"UK"*)
        LAYOUT="UK" 
        ;;
    *"Danish"*|*"DK"*)
        LAYOUT="DK"
        ;;
    *)
        # Use first 2 letters of the layout name
        LAYOUT=$(echo "$INPUT_SOURCE" | sed 's/.*\.//' | head -c 2 | tr '[:lower:]' '[:upper:]')
        ;;
esac

# Update the bar item with color coding
sketchybar --set "$NAME" label="$LAYOUT" 
