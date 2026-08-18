# Powerlevel10k theme (Manjaro-like prompt)
source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize the prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- history ---
export HISTFILE=~/.zhistory
export SAVEHIST=100000
export HISTSIZE=100000
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY
setopt HIST_VERIFY

# --- aliases ---
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias config-backup='/usr/bin/git --git-dir=$HOME/.cfg-store.git --work-tree=$HOME/.config'
alias config='/usr/bin/git --git-dir=$HOME/.cfg-store.git/ --work-tree="$HOME"'

export PATH="$HOME/.local/bin:$PATH"

# --- tab completion with menu selection ---
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(*=42=red)'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches --%f'
setopt AUTO_LIST AUTO_MENU COMPLETE_IN_WORD

# --- history substring search (Up/Down arrows) ---
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# --- autosuggestions (grey inline hints from history) ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# --- syntax highlighting (MUST stay last) ---
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- auto-start Hyprland on first TTY ---
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec Hyprland
fi
