# Login-shell environment. PATH is composed here with prepends on top of the
# system path_helper defaults — never overwritten wholesale — so nested shells
# keep whatever the parent (e.g. nvm) put on PATH.

eval "$(/opt/homebrew/bin/brew shellenv)"

# Homebrew python shims (python/pip -> python3.x)
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

# Go toolchain + go-installed binaries
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
