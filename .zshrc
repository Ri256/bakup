# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec Hyprland
fi

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias config-backup='/usr/bin/git --git-dir=$HOME/.cfg-store.git --work-tree=$HOME/.config'

export PATH="$HOME/.local/bin:$PATH"

alias config='/usr/bin/git --git-dir=$HOME/.cfg-store.git/ --work-tree="$HOME"'

export HISTFILE=~/.zhistory

export SAVEHIST=100000
export HISTSIZE=100000

setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

