: <<'EOF'
  The MIT License (MIT)
  Copyright (c) Tobey Peters
  See full license at: https://github.com/tobeypeters
EOF

[[ $- != *i* ]] && return

# ALIASES
alias ..="cd .."
alias ll="command ls -lA --color=auto"
alias cls="clear"
alias edit="code"
alias myip="curl -s ifconfig.me"
alias ip="ip --color=auto"
alias ports="sudo lsof -i -P | grep LISTEN"
alias openports="ports"

# Navigation shortcuts
alias cda="cd ~/.config/alacritty"
alias cdi="cd ~/.config/i3"
alias cdp="cd ~/.config/polybar"
alias cds="cd ~/.config/polybar/scripts"

:<<'NVIM'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
NVIM

:<<'GIT'
  Full instructions to setup git is in the file [ git_bare_repository_instructions ].
  USAGE:
    gitexec add name_of_file
    gitexec commit -m "Desired comment"
    gitexec push -u origin master
GIT
alias gitexec='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias gitadd='gitexec add'
alias gitcommit='gitexec commit -m'
alias gitpush='gitexec push --force origin master'

# Enable auto-completions
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
fzf_args="--prompt='~ ' --pointer='▶' --marker='✗' --color='light'"
alias fp="fzf --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} ||
 cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200' ${fzf_args}"
alias dm="compgen -c | fzf --bind 'enter:execute({} &>/dev/null &)' --bind 'tab:execute({})'"

set -o vi
shopt -s histappend cdspell
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=1000
HISTFILESIZE=2000

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Make man output look a tad better
if [ -t 1 ]; then
    man() {
        env LESS_TERMCAP_mb=$(printf "\e[1;33m") \
        LESS_TERMCAP_md=$(printf "\e[1;36m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;41;37m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;33m") \
        man "$@"
    }
fi

source ~/.bash_completion/alacritty

[ -f "${HOME}/.cache/wal/colors.sh" ] && . "${HOME}/.cache/wal/colors.sh"
(cat ~/.cache/wal/sequences &)

# Add executables to path
paths=(
    "$HOME/.local/bin"
    "/usr/local/go/bin"
    "$HOME/WorkSpace/Tool/android-studio/bin"
    "$HOME/Android/Sdk/platform-tools"
)
for p in "${paths[@]}"; do
    [[ ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
done
export PATH

neofetch --off --color_blocks off

# Function to get the current git branch
git_branch() {
    git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

PROMPT_COMMAND='PS1="\n  \u\h: \W $(git_branch) $ "'
