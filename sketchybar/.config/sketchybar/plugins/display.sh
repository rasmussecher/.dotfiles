#!/bin/bash

# Bind the bar to the built-in display; hide it when the built-in panel is
# inactive (clamshell mode). Runs on display_change / system_woke events and
# on a slow routine poll as a safety net. Idempotent.

STATE_FILE="${TMPDIR:-/tmp}/sketchybar_display_state"
DISPLAYS=$(sketchybar --query displays)

# Arrangement<->display mapping; arrangement ids can be renumbered on
# reconfiguration even when the same displays stay connected
CURRENT=$(echo "$DISPLAYS" | jq -c '[.[] | {a: ."arrangement-id", d: .DirectDisplayID}] | sort_by(.d)' 2>/dev/null)

# Transient query failure: leave everything untouched and retry next tick
[ -z "$CURRENT" ] && exit 0

# Fast path for events/polling: skip when the mapping is unchanged. A fresh
# start (forced via sketchybar --update in the rc) must always apply, because
# the bar's display binding resets to the default on restart.
case "$SENDER" in
  routine | display_change | system_woke)
    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$CURRENT" ]; then
      exit 0
    fi
    ;;
esac

# Built-in display's id from system_profiler (absent in clamshell mode).
# SP_OK distinguishes "no built-in display" from "detection failed".
SP_OK=0
BUILTIN_ID=""
SP_JSON=$(system_profiler SPDisplaysDataType -json 2>/dev/null)
if [ -n "$SP_JSON" ]; then
  BUILTIN_ID=$(echo "$SP_JSON" | jq -r '
    [.SPDisplaysDataType[]?.spdisplays_ndrvs[]?
     | select((.spdisplays_connection_type == "spdisplays_internal")
              or ((._name // "") | test("built-in"; "i")))
     | ._spdisplays_displayID][0] // empty' 2>/dev/null) && SP_OK=1
fi

ARRANGEMENT=""
if [ -n "$BUILTIN_ID" ]; then
  ARRANGEMENT=$(echo "$DISPLAYS" | jq -r --arg id "$BUILTIN_ID" \
    '[.[] | select(.DirectDisplayID == ($id | tonumber))][0]."arrangement-id" // empty' 2>/dev/null)
fi

if [ -n "$ARRANGEMENT" ]; then
  sketchybar --bar display="$ARRANGEMENT" hidden=off && echo "$CURRENT" > "$STATE_FILE"
elif [ "$SP_OK" = 1 ] && [ -z "$BUILTIN_ID" ]; then
  # Confirmed clamshell: built-in panel is off
  sketchybar --bar hidden=on && echo "$CURRENT" > "$STATE_FILE"
else
  # Detection failed or displays mid-transition: hide defensively but do NOT
  # latch the state, so the next event/poll retries the full logic
  sketchybar --bar hidden=on
  rm -f "$STATE_FILE"
fi
