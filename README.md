# dotfiles

macOS setup, managed with GNU Stow. AeroSpace + sketchybar + JankyBorders for
window management, Karabiner (Colemak-DH), zsh/oh-my-zsh/powerlevel10k,
AstroNvim, btop, lsd, Claude Code.

## Install

```sh
xcode-select --install
git clone https://github.com/rasmussecher/.dotfiles.git ~/github.com/rasmussecher/.dotfiles
cd ~/github.com/rasmussecher/.dotfiles && ./install.sh
```

The clone path is load-bearing — every symlink resolves through
`~/github.com/rasmussecher/.dotfiles`. HTTPS because a fresh machine has no
SSH keys yet; switch the remote once they exist.

`install.sh` is idempotent, re-run it whenever. It installs Homebrew if
missing, runs `brew bundle`, sets up oh-my-zsh, p10k and the two zsh plugins,
stows all packages, and starts sketchybar and borders via `brew services`
(launchd owns those daemons; AeroSpace doesn't start them). Conflicting files
get moved to `~/.dotfiles-backup/<timestamp>/`, never deleted.

What it can't do for you:

1. System Settings → Privacy & Security: Accessibility for AeroSpace; approve
   the Karabiner system extension; Input Monitoring for karabiner_grabber
2. git identity, `gh auth login`, ssh-keygen, then point the remote at
   `git@github.com:rasmussecher/.dotfiles.git`
3. `nvm install --lts` — nothing installs node until you do
4. open `nvim` once so lazy.nvim and mason bootstrap
5. set the Ghostty font to Hack Nerd Font (ghostty config isn't in the repo yet)
6. `exec zsh`, and once permissions are granted:
   `brew services restart sketchybar borders`

## Packages

| Package      | Links into                                          | Needs                                    |
| ------------ | --------------------------------------------------- | ---------------------------------------- |
| `aerospace`  | `~/.config/aerospace`                               | AeroSpace.app, sketchybar, borders       |
| `btop`       | `~/.config/btop`                                    | btop                                     |
| `claude`     | `~/.claude/settings.json`, `statusline-command.sh`  | Claude Code, jq                          |
| `karabiner`  | `~/.config/karabiner`                               | Karabiner-Elements                       |
| `lsd`        | `~/.config/lsd`                                     | lsd, a Nerd Font                         |
| `nvim`       | `~/.config/nvim`                                    | neovim, ripgrep, lazygit, node (via nvm) |
| `sketchybar` | `~/.config/sketchybar`                              | sketchybar, JetBrains Mono, jq           |
| `zsh`        | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`            | oh-my-zsh, p10k + plugin clones, nvm     |

## Notes

- New file in a package: `stow -R -t ~ <pkg>` from the repo root. `claude`
  stows with `--no-folding` — `~/.claude` has to stay a real directory, the
  rest of it is Claude Code runtime state.
- The Brewfile lists what these configs depend on, nothing else. `brew bundle`
  installs what's missing and doesn't touch what's there. For a full-machine
  snapshot: `brew bundle dump --file=Brewfile.full`.
- Sync another machine: `git pull && ./install.sh`.

## TODO

ghostty and git packages, bordersrc, Mason `ensure_installed` for the
Angular/TS toolchain, settle brew node vs nvm.
