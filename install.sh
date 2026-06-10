#!/usr/bin/env bash
# Bootstrap a fresh Mac from this repo — or converge an existing one.
# Idempotent: safe to re-run any time; nothing is ever deleted, conflicting
# files are moved to ~/.dotfiles-backup/<timestamp>/.
#
# Compatible with the stock macOS bash 3.2 (a fresh Mac has nothing newer).
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
# claude is stowed separately with --no-folding (see step 5)
STOW_PACKAGES=(aerospace btop karabiner lsd nvim sketchybar zsh)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*"; }

# ── 0. Preflight ─────────────────────────────────────────────────────────
[ "$(uname -s)" = Darwin ] || { echo "macOS only." >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || warn "Intel Mac: zsh/.zprofile assumes /opt/homebrew — expect breakage"
if ! xcode-select -p >/dev/null 2>&1; then
  log "Xcode Command Line Tools are required. Accept the dialog, then re-run ./install.sh"
  xcode-select --install || true
  exit 1
fi

# ── 1. Homebrew ──────────────────────────────────────────────────────────
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  log "Installing Homebrew (will ask for your password)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── 2. Brewfile ──────────────────────────────────────────────────────────
# Install what's missing, but never surprise-upgrade what's already there —
# upgrades are a deliberate `brew upgrade`, not a side effect of re-running this.
export HOMEBREW_BUNDLE_NO_UPGRADE=1
if brew bundle check --file="$DOTFILES_DIR/Brewfile" >/dev/null 2>&1; then
  log "Brewfile already satisfied"
else
  log "brew bundle (karabiner-elements is a .pkg — sudo password will be requested)"
  brew bundle install --file="$DOTFILES_DIR/Brewfile"
fi

# ── 3. oh-my-zsh + theme/plugin clones (before stow: the omz installer ───
#       writes a template ~/.zshrc on a fresh machine; step 4 moves it aside)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_if_missing() { [ -d "$2" ] || git clone --depth=1 "$1" "$2"; }
clone_if_missing https://github.com/romkatv/powerlevel10k.git         "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ── 4. Pre-stow guards + backup of conflicting files ─────────────────────
# These MUST exist as real directories before stowing. If ~/.config is
# missing, stow folds ALL of it into a repo symlink and every app's runtime
# state lands in git; same story for ~/.claude (Claude Code runtime state).
mkdir -p "$HOME/.config" "$HOME/.claude" "$HOME/.cache" "$HOME/.nvm"

backup_conflicts() { # $1 = package name
  local f rel target
  while IFS= read -r -d '' f; do
    rel="${f#"$DOTFILES_DIR/$1/"}"
    target="$HOME/$rel"
    # Same inode (directly, or through a folded parent symlink) = already
    # stowed; -ef follows symlinks, so repo files are never moved aside.
    [ "$target" -ef "$f" ] && continue
    if [ -e "$target" ] || [ -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      warn "moved aside ~/$rel -> $BACKUP_DIR/$rel"
    fi
  done < <(find "$DOTFILES_DIR/$1" -type f ! -name '.DS_Store' -print0)
}
for pkg in "${STOW_PACKAGES[@]}" claude; do backup_conflicts "$pkg"; done

# ── 5. Stow (restow -R = converge on re-runs) ────────────────────────────
log "Stowing packages"
cd "$DOTFILES_DIR"
stow -R -t "$HOME" --ignore='\.DS_Store' "${STOW_PACKAGES[@]}"
stow -R -t "$HOME" --ignore='\.DS_Store' --no-folding claude  # ~/.claude must stay a real dir
chmod +x aerospace/.config/aerospace/scripts/*.sh \
         sketchybar/.config/sketchybar/plugins/*.sh \
         claude/.claude/statusline-command.sh

# ── 6. Services & apps ───────────────────────────────────────────────────
# sketchybar/borders are owned by brew services (KeepAlive) — AeroSpace
# deliberately does not launch them. Fonts were installed in step 2, so the
# bar renders correctly on first start.
service_started() { brew services list | grep -Eq "^$1[[:space:]]+started"; }
service_started sketchybar || { log "Starting sketchybar"; brew services start sketchybar; }
service_started borders    || { log "Starting borders";    brew services start borders; }
open -ga AeroSpace 2>/dev/null || true           # aerospace.toml: start-at-login = true
open -ga Karabiner-Elements 2>/dev/null || true  # triggers the driver-approval prompts

# ── 7. What can't be automated ───────────────────────────────────────────
cat <<'EOF'
─────────────────────────────────────────────────────────────────────
Done. Remaining manual steps:
 1. System Settings -> Privacy & Security -> Accessibility: enable AeroSpace
 2. Karabiner: approve the system extension when prompted, then
    Privacy & Security -> Input Monitoring: enable karabiner_grabber
 3. git config --global user.name "..." && git config --global user.email "..."
 4. gh auth login
 5. ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub
    git -C ~/github.com/rasmussecher/.dotfiles remote set-url origin \
        git@github.com:rasmussecher/.dotfiles.git
 6. nvm install --lts        (nothing installs node until you do)
 7. Open nvim once — lazy.nvim and mason bootstrap themselves
 8. Set the Ghostty font to "Hack Nerd Font" (ghostty config not in repo yet)
 9. exec zsh                 (load the stowed .zprofile/.zshrc)
After granting permissions: brew services restart sketchybar borders
─────────────────────────────────────────────────────────────────────
EOF
