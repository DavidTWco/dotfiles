# David Wood's .zshrc Configuration
#	dotfiles: https://github.com/davidtwco/dotfiles
#	website: https://davidtw.co
# ==================================================

# Functions {{{
# =========
_has() {
    which $1>/dev/null 2>&1
}
# }}}

# Bindings {{{
# ========
# Use vim keybindings.
set -o vi
bindkey -v

# Bind keys for Surface and other strange keyboards.
bindkey "^?" backward-delete-char
bindkey "^W" backward-kill-word
bindkey "^H" backward-delete-char
bindkey "^U" backward-kill-line
bindkey "[3~" delete-char
bindkey "[7~" beginning-of-line
bindkey "[1~" beginning-of-line
bindkey "[8~" end-of-line
bindkey "[4~" end-of-line

# Bind keys for history search
bindkey "" history-incremental-pattern-search-backward

# Disable control flow, allows CTRL+S to be used.
stty -ixon
# }}}

# Environment {{{
# ===========
# Set a cache dir.
export ZSH_CACHE_DIR=$HOME/.zsh/cache

# Set the correct gpg tty.
export GPG_TTY=$(tty)

# 10ms for key sequences
export KEYTIMEOUT=1

# Ensure editor is Vim
export EDITOR=vim

# Ensure Vim and others use 256 colours.
if [[ "$TERM" != "screen"* && "$TERM" != "tmux"* ]]; then
    export TERM=xterm-256color
fi

# Set Go directory
export GOPATH=$HOME/.go

# Allow Vagrant to access Windows outside of WSL.
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"

# Don't clear the screen when leaving man.
export MANPAGER='less -X'

# Enable persistent REPL history for node.
export NODE_REPL_HISTORY="$HOME/.node_history"

# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE='sloppy'

# Connect to Docker over TCP. Allows connections to Docker for Windows.
if grep -q Microsoft /proc/version; then
    export DOCKER_HOST=tcp://127.0.0.1:2375
fi
# }}}

# SSH Agent {{{
# =========
env=~/.ssh/agent.env

agent_load_env () { test -f "$env" && . "$env" >| /dev/null ; }

agent_start () {
    (umask 077; ssh-agent >| "$env")
    . "$env" >| /dev/null ;
}

agent_load_env

# agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2= agent not running
agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)

if [ ! "$SSH_AUTH_SOCK" ] || [ $agent_run_state = 2 ]; then
    agent_start
    ssh-add
elif [ "$SSH_AUTH_SOCK" ] && [ $agent_run_state = 1 ]; then
    ssh-add
fi

unset env
# }}}

# GPG Agent {{{
# =========
export GPG_TTY=$(tty)
if _has gpg-agent; then
    eval "$(gpg-agent --daemon)"
fi
# }}}

# Path {{{
# ====
# In zsh, the $PATH variable is tied to the $path variable.
# This makes the $path variable act like a set.
typeset -U path

# Add our directories.
path=("$HOME/bin" $path)
path=("$HOME/.cargo/bin" $path)
path=("$HOME/.go/bin" $path)
path=("$HOME/.local/bin" $path)
path=("/opt/puppetlabs/bin" $path)
path=("$HOME/.fzf/bin" $path)

# Using the (N-/) glob qualifier we can remove paths that do not exist.
path=($^path(N-/))
# }}}

# Completion {{{
# ==========
# Use modern completion system.
autoload -Uz compinit; compinit -i

# Add any completions.
fpath+=~/.yadm/completions

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# tmuxinator completion.
source ~/.yadm/completions/tmuxinator.zsh

# npm completion
if _has npm; then
    source <(npm completion)
fi
# }}}

# History {{{
# =======
setopt histignorealldups sharehistory

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
# }}}

# Aliases {{{
# =======
# Load our aliases.
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi
# }}}

# antibody {{{
# =======
if _has antibody; then
    # If plugins have not been generated, then generate them.
    if [[ ! -e "$HOME/.zsh_plugins.sh" ]]; then
        # Load antibody.
        source <(antibody init)

        # Update and install plugins.
        bash -c 'antibody bundle < "$HOME/.antibody_bundle" >> "$HOME/.zsh_plugins.sh"'
        antibody update
    fi

    # Load plugins.
    source "$HOME/.zsh_plugins.sh"
fi

# Bind keys for zsh-history-substring-search
bindkey "OA" history-substring-search-up
bindkey "OB" history-substring-search-down

# }}}

# fasd {{{
# =====
if _has fasd; then
    fasd_cache="$ZSH_CACHE_DIR/fasd-init-cache"
    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
        fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >| "$fasd_cache"
    fi
    source "$fasd_cache"
    unset fasd_cache
fi
# }}}

# fzf {{{
# ===
# fzf via Homebrew
if [ -e /usr/local/opt/fzf/shell/completion.zsh ]; then
    source /usr/local/opt/fzf/shell/key-bindings.zsh
    source /usr/local/opt/fzf/shell/completion.zsh
fi

# fzf via local installation
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# fzf + ag configuration
if _has fzf && _has ag; then
    export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='
    --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
    --color info:108,prompt:109,spinner:108,pointer:168,marker:168
    '
fi
# }}}

# up {{{
# ==
source $HOME/.yadm/external/up/up.sh
# }}}

# Prompt {{{
# ======
autoload -Uz promptinit; promptinit

VIM_PROMPT="❯"
PROMPT='%(12V.%F{242}${psvar[12]}%f .)'
PROMPT+='%(?.%F{magenta}.%F{red})${VIM_PROMPT}%f '

PURE_GIT_DOWN_ARROW='↓'
PURE_GIT_UP_ARROW='↑'

prompt_pure_update_vim_prompt() {
    zle || {
    print "error: pure_update_vim_prompt must be called when zle is active"
    return 1
}
VIM_PROMPT=${${KEYMAP/vicmd/❮}/(main|viins)/❯}
zle .reset-prompt
}

function zle-line-init zle-keymap-select {
prompt_pure_update_vim_prompt
}
zle -N zle-line-init
zle -N zle-keymap-select
# }}}

# vim:foldmethod=marker:foldlevel=0
