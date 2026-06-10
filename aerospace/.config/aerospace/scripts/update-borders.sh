#!/bin/bash

# Active-window border is prominent only when the focused workspace holds
# more than one window; hidden when a window is alone on screen.
# Triggered by AeroSpace on focus/workspace changes (see aerospace.toml).

# AeroSpace launches commands without the Homebrew PATH
export PATH="/opt/homebrew/bin:$PATH"

COUNT=$(aerospace list-windows --workspace focused --count 2>/dev/null)
[ -z "$COUNT" ] && exit 0

if [ "$COUNT" -gt 1 ]; then
  borders active_color=0xFFFF9F0A inactive_color=0x00 width=4.0
else
  borders active_color=0x00000000 inactive_color=0x00 width=4.0
fi
