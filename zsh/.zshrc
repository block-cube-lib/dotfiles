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

# hook
autoload -Uz add-zsh-hook

# vcs
autoload -Uz vcs_info
add-zsh-hook precmd vcs_info

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

# prompt
function left_prompt()
{
  # git branch name
  local git_status=""
  if [[ -n "${vcs_info_msg_0_}" ]]; then
    git_status="${vcs_info_msg_0_}"
  fi

  # current directory
  local current_dir="%{$fg[cyan]%}%~%{$reset_color%}"

  # >>>
  local command_line_header=""
  command_line_header="${command_line_header}%{$fg_bold[red]%}>%{$reset_color%}"
  command_line_header="${command_line_header}%{$fg_bold[yellow]%}>%{$reset_color%}"
  command_line_header="${command_line_header}%{$fg_bold[green]%}>%{$reset_color%}"

  # empty line
  PROMPT="
${current_dir} ${git_status}
${command_line_header} "
}

function right_prompt()
{
  if [[ ${?} -eq 0 ]]; then
    RPROMPT="%{$fg[blue]%}o%{$reset_color%}"
  else
    RPROMPT="%{$fg[red]%}x $?%{$reset_color%}"
  fi
}

add-zsh-hook precmd left_prompt
add-zsh-hook precmd right_prompt
