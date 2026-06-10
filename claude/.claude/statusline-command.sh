#!/usr/bin/env bash
# Claude Code status line — compact two-line design (truecolor).
#
# Line 1: ◆ <model> [· effort] │ ctx:<pct>% [<size> ⚠] │ 5h:% ⟳ HH:MM · 7d:% ⟳ <weekday>
# Line 2: ⎇ <branch>[*] │ +added/-removed │ <project>
#
# All data comes from the JSON Claude Code pipes on stdin (see
# https://code.claude.com/docs/en/statusline). Requires a truecolor terminal
# (Ghostty/iTerm2/Kitty) and a powerline-capable font for the branch glyph.

input=$(cat)

# --- parse all fields in a single jq pass (one value per line) ---
# One-per-line (not @tsv) so empty optional fields are preserved; tab is an
# IFS-whitespace char, so `read` would collapse adjacent tabs and shift fields.
# `while read` (not mapfile) for bash 3.2 compatibility — macOS ships /bin/bash 3.2.
F=()
while IFS= read -r line; do F+=("$line"); done < <(printf '%s' "$input" | jq -r '
  .model.display_name // "Claude",
  (.effort.level // ""),
  (.context_window.used_percentage // 0),
  (.context_window.context_window_size // 0),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.rate_limits.seven_day.resets_at // ""),
  (.workspace.project_dir // .cwd // ""),
  (.cwd // ""),
  (.session_id // "nosession")
')
MODEL=${F[0]}; EFFORT=${F[1]}; PCT=${F[2]}; CTX_SIZE=${F[3]}
ADDED=${F[4]}; REMOVED=${F[5]}; FIVE_H=${F[6]}; FIVE_RESET=${F[7]}
SEVEN_D=${F[8]}; SEVEN_RESET=${F[9]}
PROJECT_DIR=${F[10]}; CWD=${F[11]}; SESSION_ID=${F[12]}

# --- palette (24-bit truecolor; ESC bytes are real via $'...') ---
RESET=$'\033[0m'
BOLD=$'\033[1m'
VIOLET=$'\033[38;2;167;139;250m'   # diamond
LIGHT=$'\033[38;2;229;231;235m'    # model name
SEP=$'\033[38;2;75;85;99m'         # separators / dim
GREEN=$'\033[38;2;74;222;128m'
AMBER=$'\033[38;2;251;191;36m'
RED=$'\033[38;2;248;113;113m'
GRAY=$'\033[38;2;148;163;184m'     # neutral / secondary text
BLUE=$'\033[38;2;96;165;250m'      # project name

# --- glyphs baked to real UTF-8 bytes ---
printf -v DIAMOND  '\xe2\x97\x86'        # ◆ U+25C6
printf -v WARN     '\xe2\x9a\xa0'        # ⚠ U+26A0
printf -v BRANCHIC '\xee\x82\xa0'        # powerline branch U+E0A0
printf -v VBAR     '\xe2\x94\x82'        # │ U+2502
printf -v RESETIC  '\xe2\x9f\xb3'        # ⟳ U+27F3
printf -v MDOT     '\xc2\xb7'            # · U+00B7
S=" ${SEP}${VBAR}${RESET} "              # segment separator

# --- integer percentage (clamped 0..100) ---
PCT_INT=$(printf '%.0f' "${PCT:-0}" 2>/dev/null || echo 0)
[ "$PCT_INT" -lt 0 ] 2>/dev/null && PCT_INT=0
[ "$PCT_INT" -gt 100 ] 2>/dev/null && PCT_INT=100

# --- percentage color by threshold ---
if [ "$PCT_INT" -ge 90 ]; then PCT_COLOR="$RED"
elif [ "$PCT_INT" -ge 70 ]; then PCT_COLOR="$AMBER"
else PCT_COLOR="$GREEN"; fi

# --- context-size label + warning, shown only when usage is high ---
CTX_LABEL=""
if [ "$PCT_INT" -ge 70 ] && [ "${CTX_SIZE:-0}" -gt 0 ] 2>/dev/null; then
  if [ "$CTX_SIZE" -ge 1000000 ]; then size="$(( CTX_SIZE / 1000000 ))M"
  elif [ "$CTX_SIZE" -ge 1000 ]; then size="$(( CTX_SIZE / 1000 ))k"
  else size="$CTX_SIZE"; fi
  if [ "$PCT_INT" -ge 90 ]; then
    CTX_LABEL=" ${AMBER}${WARN}${RESET} ${GRAY}${size}${RESET}"
  else
    CTX_LABEL=" ${GRAY}${size}${RESET}"
  fi
fi

# --- model segment (prefix "Claude " when not already present) ---
case "$MODEL" in
  Claude*) MODEL_NAME="$MODEL" ;;
  *) MODEL_NAME="Claude $MODEL" ;;
esac

# --- rate-limit segment (Claude.ai subscribers only, after first response) ---
# Format: <label>:<used>% ⟳ <reset display> — local HH:MM for the 5h window,
# weekday name for the 7d window (HH:MM once it's less than a day out).
# Color reflects projected usage at reset (used% / elapsed-fraction-of-window,
# stateless pace math from resets_at) — red means "on pace to exhaust before
# the window resets", not merely "currently high". The projection itself is
# not displayed, it only drives the color.
rl_color() {
  local v; v=$(printf '%.0f' "$1")
  if [ "$v" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$v" -ge 50 ]; then printf '%s' "$AMBER"
  else printf '%s' "$GRAY"; fi
}
fmt_eta() {
  local s=$1 d h m
  d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else printf '<1m'; fi
}
fmt_at() {
  # epoch -> local time via strftime format; BSD date (macOS) first, GNU fallback
  date -r "$1" +"$2" 2>/dev/null || date -d "@$1" +"$2" 2>/dev/null
}
NOW=$(date +%s)
rl_segment() {
  # $1 label, $2 used_percentage, $3 resets_at (epoch, may be empty), $4 window length (s),
  # $5 reset display style: "clock" = local HH:MM, "day" = weekday (clock when <24h away),
  #    anything else = countdown (e.g. 2d4h)
  local label=$1 used=$2 resets=$3 window=$4 style=$5
  [ -z "$used" ] && return
  local used_int u10 proj="" eta="" color
  used_int=$(printf '%.0f' "$used")
  # used% in tenths for integer projection math; 10# guards octal on "0.x" -> "0x"
  u10=$(printf '%.1f' "$used"); u10=$(( 10#${u10/./} ))
  if [ -n "$resets" ]; then
    resets=$(printf '%.0f' "$resets")
    local remaining=$(( resets - NOW ))
    [ "$remaining" -lt 0 ] && remaining=0
    [ "$remaining" -gt "$window" ] && remaining=$window
    local elapsed=$(( window - remaining ))
    # project only past 10% of the window — earlier extrapolation is noise
    if [ "$elapsed" -ge $(( window / 10 )) ] && [ "$used_int" -ge 1 ]; then
      proj=$(( (u10 * window / elapsed + 5) / 10 ))
      [ "$proj" -gt 999 ] && proj=999
    fi
    case "$style" in
      clock) eta=$(fmt_at "$resets" '%H:%M') ;;
      day)
        if [ "$remaining" -lt 86400 ]; then eta=$(fmt_at "$resets" '%H:%M')
        else eta=$(fmt_at "$resets" '%a'); fi
        ;;
      *) eta=$(fmt_eta "$remaining") ;;
    esac
  fi
  if [ -n "$proj" ]; then
    if [ "$proj" -ge 100 ]; then color=$RED
    elif [ "$proj" -ge 85 ]; then color=$AMBER
    else color=$GRAY; fi
  else
    color=$(rl_color "$used")
  fi
  local seg="${color}${label}:${used_int}%${RESET}"
  [ -n "$eta" ] && seg="${seg} ${GRAY}${RESETIC} ${eta}${RESET}"
  printf '%s' "$seg"
}
RL_SEG=$(rl_segment "5h" "$FIVE_H" "$FIVE_RESET" 18000 clock)
RL7=$(rl_segment "7d" "$SEVEN_D" "$SEVEN_RESET" 604800 day)
[ -n "$RL7" ] && RL_SEG="${RL_SEG:+$RL_SEG ${SEP}${MDOT}${RESET} }$RL7"

# --- git branch + dirty flag (cached 3s per session to avoid lag) ---
CACHE="/tmp/cc-statusline-git-$SESSION_ID"
cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
if [ ! -f "$CACHE" ] || [ "$cache_age" -gt 3 ]; then
  if git -C "$CWD" rev-parse --git-dir >/dev/null 2>&1; then
    b=$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null || git -C "$CWD" rev-parse --short HEAD 2>/dev/null)
    if [ -n "$(git -C "$CWD" status --porcelain 2>/dev/null)" ]; then d="*"; else d=""; fi
    printf '%s\t%s' "$b" "$d" > "$CACHE"
  else
    printf '\t' > "$CACHE"
  fi
fi
IFS=$'\t' read -r BRANCH DIRTY < "$CACHE"

# --- project name (basename only) ---
PROJECT="${PROJECT_DIR##*/}"
[ -z "$PROJECT" ] && PROJECT="${CWD##*/}"
[ -z "$PROJECT" ] && PROJECT="/"

# ===== assemble line 1 (string concat; all vars hold real bytes) =====
L1="${VIOLET}${DIAMOND}${RESET} ${BOLD}${LIGHT}${MODEL_NAME}${RESET}"
[ -n "$EFFORT" ] && L1="${L1} ${SEP}${MDOT}${RESET} ${GRAY}${EFFORT}${RESET}"
L1="${L1}${S}${PCT_COLOR}ctx:${PCT_INT}%${RESET}${CTX_LABEL}"
[ -n "$RL_SEG" ] && L1="${L1}${S}${RL_SEG}"

# ===== assemble line 2 =====
L2=""
[ -n "$BRANCH" ] && L2="${GRAY}${BRANCHIC} ${BRANCH}${DIRTY}${RESET}"
if [ "${ADDED:-0}" -gt 0 ] 2>/dev/null || [ "${REMOVED:-0}" -gt 0 ] 2>/dev/null; then
  lines_seg="${GREEN}+${ADDED}${SEP}/${RED}-${REMOVED}${RESET}"
  L2="${L2:+$L2$S}$lines_seg"
fi
L2="${L2:+$L2$S}${BLUE}${PROJECT}${RESET}"

# ===== output =====
printf '%s\n%s\n' "$L1" "$L2"
