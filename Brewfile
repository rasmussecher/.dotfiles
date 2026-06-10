# Curated essentials — only what the dotfiles need to function.
# Deliberately NOT a machine dump; add tools here only when a config
# in this repo depends on them. (Snapshot everything else any time
# with: brew bundle dump --file=Brewfile.full)

tap "nikitabobko/tap"        # aerospace
tap "felixkratz/formulae"    # sketchybar, borders

# The backbone
brew "stow"

# CLI tools the configs call directly
brew "jq"                    # claude statusline-command.sh, sketchybar plugins/display.sh
brew "lsd"                   # lsd package
brew "btop"                  # btop package
brew "nvm"                   # sourced by zsh/.zshrc (guarded)
brew "gh"                    # GitHub auth on a fresh machine

# Editor (nvim package = AstroNvim; lazy.nvim/mason self-bootstrap on first run)
brew "neovim"
brew "ripgrep"               # telescope live_grep
brew "lazygit"               # <leader>gg

# Desktop: tiling WM, bar, borders, keyboard remap, terminal
brew "felixkratz/formulae/sketchybar"
brew "felixkratz/formulae/borders"
cask "nikitabobko/tap/aerospace"
cask "karabiner-elements"
cask "ghostty"

# Fonts (in core homebrew/cask — no cask-fonts tap needed)
cask "font-jetbrains-mono"   # sketchybarrc icon/label font
cask "font-hack-nerd-font"   # terminal font; lsd "fancy" icons need a Nerd Font
