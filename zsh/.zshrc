###
# history
###
# file
mkdir -p ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/
export HISTFILE=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zhistory


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

# color
autoload -Uz colors
colors

# vcs
autoload -Uz vcs_info
precmd () { vcs_info }

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

# prompt
function left_prompt
{
  # empty line
  local prompt="\n"

  # current directory
  prompt="${prompt}%{$fg[cyan]%}%~%{$reset_color%}"

  # git branch name
  if [[ -n "${vcs_info_msg_0_}" ]]; then
    prompt="${prompt} ${vcs_info_msg_0_}"
  fi

  # empty line
  local prompt="${prompt}\n"

  # >>>
  prompt="${prompt}%{$fg_bold[red]%}>%{$reset_color%}"
  prompt="${prompt}%{$fg_bold[yellow]%}>%{$reset_color%}"
  prompt="${prompt}%{$fg_bold[green]%}>%{$reset_color%}"
  prompt="${prompt} "

  echo -e ${prompt}
}

function right_prompt
{
  if [[ ${?} -eq 0 ]]; then
    echo %{$fg[blue]%}o%{$reset_color%}
  else
    echo %{$fg[red]%}x $?%{$reset_color%}
  fi
}

PROMPT="`left_prompt`"
RPROMPT="`right_prompt`"
