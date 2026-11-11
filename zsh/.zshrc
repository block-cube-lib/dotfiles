###
# Shared zsh settings.
# Loaded from ~/.zshrc on each machine:
#   source "$HOME/.config/zsh/.zshrc"
# Machine-specific lines belong in ~/.zshrc.local,
# which is loaded near the end of this file.
###

# history
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
export HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zhistory"
export HISTSIZE=10000
export SAVEHIST=10000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

# history search by prefix
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end

# completion (needed before zsh-z registers its completion)
autoload -Uz compinit
compinit

# zsh-z directory jumper (cloned to ~/zsh_plugins on each machine)
if [[ -f "$HOME/zsh_plugins/zsh-z/zsh-z.plugin.zsh" ]]; then
  source "$HOME/zsh_plugins/zsh-z/zsh-z.plugin.zsh"
fi

# Use nvr as the git editor inside a Neovim terminal
if [[ -n "$NVIM" || -n "$NVIM_LISTEN_ADDRESS" ]]; then
  export GIT_EDITOR="nvr -cc split --remote-wait"
fi

# Machine-specific settings that are not kept in this repository.
# Loaded before the prompt setup so PATH additions made there
# (Homebrew, cargo, ...) are already in effect.
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# prompt (initialised last, after all PATH setup)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
