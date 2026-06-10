# .dotfiles

GNU Stow–managed macOS setup: AeroSpace (tiling WM) + sketchybar + JankyBorders,
Karabiner (Colemak-DH), zsh + oh-my-zsh + powerlevel10k, AstroNvim, lsd, btop,
and Claude Code config.

## New Mac in 3 commands

```sh
xcode-select --install
git clone https://github.com/rasmussecher/.dotfiles.git ~/github.com/rasmussecher/.dotfiles
cd ~/github.com/rasmussecher/.dotfiles && ./install.sh
```

> HTTPS clone on purpose — a fresh Mac has no SSH keys yet (switch the remote
> later, see below). The path matters: every symlink resolves through
> `~/github.com/rasmussecher/.dotfiles`.

## What install.sh does

1. Verifies Xcode Command Line Tools (exits with instructions if missing)
2. Installs Homebrew if absent
3. `brew bundle` against the curated [Brewfile](Brewfile) — installs what's
   missing, never upgrades what's already there
4. Installs oh-my-zsh (unattended) and clones powerlevel10k,
   zsh-autosuggestions, zsh-syntax-highlighting into `$ZSH_CUSTOM`
5. Stows every package into `$HOME` (`claude` with `--no-folding` — `~/.claude`
   must stay a real directory, the rest of it is Claude Code runtime state)
6. Starts sketchybar + borders via `brew services` (they own the daemons —
   AeroSpace deliberately does not launch them), opens AeroSpace and
   Karabiner-Elements to trigger their permission prompts

**Idempotent — re-run any time.** Nothing is deleted: conflicting files are
moved to `~/.dotfiles-backup/<timestamp>/`.

## Manual steps after install

1. Privacy & Security → Accessibility: enable **AeroSpace**
2. Approve the Karabiner system extension; Input Monitoring: enable
   **karabiner_grabber**
3. `git config --global user.name "..."` / `user.email "..."`
4. `gh auth login`
5. `ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub`, then
   `git -C ~/github.com/rasmussecher/.dotfiles remote set-url origin git@github.com:rasmussecher/.dotfiles.git`
6. `nvm install --lts` (nothing installs node until you do)
7. Open `nvim` once — lazy.nvim and mason bootstrap themselves
8. Set the Ghostty font to *Hack Nerd Font* (ghostty config not in the repo yet)
9. `exec zsh`, and after granting permissions:
   `brew services restart sketchybar borders`

## Packages

| Package      | Links into                                       | External requirements                          |
| ------------ | ------------------------------------------------ | ---------------------------------------------- |
| `aerospace`  | `~/.config/aerospace`                            | AeroSpace.app, sketchybar, borders             |
| `btop`       | `~/.config/btop`                                 | btop                                           |
| `claude`     | `~/.claude/settings.json`, `statusline-command.sh` | Claude Code, jq                              |
| `karabiner`  | `~/.config/karabiner`                            | Karabiner-Elements                             |
| `lsd`        | `~/.config/lsd`                                  | lsd, a Nerd Font                               |
| `nvim`       | `~/.config/nvim`                                 | neovim, ripgrep, lazygit, node (via nvm)       |
| `sketchybar` | `~/.config/sketchybar`                           | sketchybar, JetBrains Mono, jq                 |
| `zsh`        | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh`         | oh-my-zsh, p10k + plugin clones, nvm           |

## Day-2 operations

- **Add a file to a package**: drop it in the package tree, then
  `stow -R -t ~ <pkg>` from the repo root (`--no-folding` for `claude`)
- **Sync a machine with the repo**: `git pull && ./install.sh`
- **Brewfile is curated, not dumped** — add a tool only when a config in this
  repo depends on it. Full-machine snapshot if you ever want one:
  `brew bundle dump --file=Brewfile.full`

## Future work (deliberately deferred)

ghostty + git stow packages, `bordersrc`, nvim Mason `ensure_installed` for the
Angular/TS toolchain, node-toolchain consolidation (brew node vs nvm).
