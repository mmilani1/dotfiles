# Initialize Homebrew if not already in PATH
if ! command -v brew &>/dev/null; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"

# Directory Navigation & History Options
setopt AUTO_CD
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS

# GPG Agent & SSH Socket Integration
if command -v gpgconf &>/dev/null; then
    export GPG_TTY="$(tty)"
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent 2>/dev/null
fi

# Completion System Initialization
if [[ -d "$HOME/.cache/antidote/github.com/zsh-users/zsh-completions/src" ]]; then
    fpath=("$HOME/.cache/antidote/github.com/zsh-users/zsh-completions/src" $fpath)
fi
autoload -Uz compinit
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"

# Tool Integrations
command -v fzf &>/dev/null && source <(fzf --zsh)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"
command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Antidote Plugin Manager
if command -v brew &>/dev/null; then
    ANTIDOTE_PATH="$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
    if [[ -f "$ANTIDOTE_PATH" ]]; then
        source "$ANTIDOTE_PATH"
        antidote load "$HOME/.zsh_plugins.txt"
    fi
fi

# Highlight zsh-abbr abbreviations and feed into autosuggestions
if (( ${#ABBR_REGULAR_USER_ABBREVIATIONS} )); then
    ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp)
    ZSH_HIGHLIGHT_REGEXP+=("^[[:blank:][:space:]]*(${(j:|:)${(@Qk)ABBR_REGULAR_USER_ABBREVIATIONS}})$" fg=magenta,bold)
fi
if (( ${#ABBR_GLOBAL_USER_ABBREVIATIONS} )); then
    ZSH_HIGHLIGHT_HIGHLIGHTERS+=(regexp)
    ZSH_HIGHLIGHT_REGEXP+=("\<(${(j:|:)${(@Qk)ABBR_GLOBAL_USER_ABBREVIATIONS}})$" fg=magenta,bold)
fi
ZSH_AUTOSUGGEST_STRATEGY=(abbreviations ${ZSH_AUTOSUGGEST_STRATEGY[@]})

# History Substring Search Keybindings
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# Local Secrets & Bitwarden CLI Helpers (zero plaintext secrets in Git)
if [[ -f "$HOME/.config/secrets.env" ]]; then
    chmod 600 "$HOME/.config/secrets.env"
    source "$HOME/.config/secrets.env"
fi

bw-unlock() {
    export BW_SESSION="$(bw unlock --raw)"
}

bw-sync-secrets() {
    local item="${1:-dotfiles-secrets}"
    if [[ -z "${BW_SESSION:-}" ]]; then
        bw-unlock || return 1
    fi
    mkdir -p "$HOME/.config"
    (umask 077 && bw get notes "$item" > "$HOME/.config/secrets.env") &&
        source "$HOME/.config/secrets.env" &&
        echo "Synced secrets from Bitwarden item '$item' into ~/.config/secrets.env"
}

# Helper Functions
whats-running-on-port() {
    if [[ $# -eq 0 ]]; then
        lsof -iTCP -sTCP:LISTEN -n -P
    else
        lsof -iTCP:"$1" -sTCP:LISTEN -n -P
    fi
}

urldecode() {
    local input="${1:-$(cat)}"
    python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))' "$input"
}
