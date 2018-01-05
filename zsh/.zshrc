###
# history
###
# file
export HISTFILE=${XDG_CACHE_HOME}/zsh/.zhistory

# count of history to save in memory
export HISTSIZE=1000

# count of history to save in file
export SAVEHIST=10000

# ignore duplicates
setopt hist_ignore_dups

# save begin and end time
setopt EXTENDED_HISTORY

# completion
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
