export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
export PATH=/opt/homebrew/opt/python@3.13/libexec/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/usr/local/go/bin:/Users/rs/go/bin

export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# Load Angular CLI autocompletion.
source <(ng completion script)

export GPG_TTY=$(tty)

# JankyBorders : window borders
alias jankyon="pkill -f borders; brew services restart borders && sleep 1 && borders active_color=0x009A0083 inactive_color=0x00ffffff width=5.0 style=round > /dev/null 2>&1 &"
alias jankyoff="pkill -f borders && brew services stop borders"

# Restart everything
alias rsa="brew services restart sketchybar && killall AeroSpace && sleep 2 && open -a AeroSpace"

. "$HOME/.local/bin/env"
