echo ''<<LICENSE
	The MIT License(MIT)
	Copyright(c), Tobey Peters, https://github.com/tobeypeters
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the "Software"), to deal in the Software without restriction,
	including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
	 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
LICENSE

[[ $- != *i* ]] && return

# --------------------------- ALIASES START
alias ..='cd ..'
alias ls='ls -A --group-directories-first --color=auto'
alias ll='ls -l'

alias myip='curl ip.appspot.com' 			# Public facing IP Address
alias ports='sudo lsof -i -P'				# Display open sockets
alias openports='ports | grep LISTEN'		# All listening connections
alias showBlocked='sudo ipfw list'			# All ipfw rules inc/ blocked IPs
alias ipconfig='ifconfig'					# sudo apt install net-tools

alias ip='ip --color=auto'                  # always have color

alias edit='code'							# Use VSCode as my editor

alias machineinfo='sudo dmidecode'			# Hardware info. You have hwinfo to

alias vim=nvim								# Use nvim instead of vim

alias cdi='cd ~/.config/i3'					# Quickly jump my i3 folder
alias cdp='cd ~/.config/polybar' 			# Quickly jump my polybar folder
alias cds='cd ~/.config/polybar/scripts'	# Quickly jump my polybar scripts folder

# Full instructions to setup git is in the file [ git_bare_repository_instructions ].
# Cause, I can use to to upload more than just config files,I renamed it to gitexec.
# USAGE:
#       gitexec add name_of_file
#       gitexec commit -m "Desired comment"
#       gitexec push -u origin master

alias gitexec='/usr/bin/git --git-dir=/home/tibegato/dotfiles/ --work-tree=$HOME'
alias gitadd="gitexec add"
alias gitcommit="gitexec commit -m"
alias gitpush="gitexec push --force origin master"
# --------------------------- ALIASES STOP

# --------------------------- HISTORY START
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

HISTSIZE=100
HISTFILESIZE=100
# --------------------------- HISTORY STOP

set -o vi

set completion-ignore-case on

shopt -s cdspell

complete -d cd

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Nake man output look a tad better
man() {
    env LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}
# --------------------------- MAKE MAN PRETTY STOP

# --------------------------- EXTRACT START
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2) tar xjf $1;;
            *.tar.gz) tar xzf $1;;
            *.bz2) bunzip2 $1;;
            *.rar) rar x $1;;
            *.gz) gunzip $1;;
            *.tar) tar xf $1;;
            *.tbz2) tar xjf $1;;
            *.tgz) tar xzf $1;;
            *.zip) unzip $1;;
            *.Z) uncompress $1;;
            *.7z) 7z x $1;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
# --------------------------- EXTRACT STOP

# --------------------------- PROMPT START
h2d() {
  echo "ibase=16; $@"|bc
}

complete -cf sudo

NC="\[\033[00m\]"

COLOR1=`xrdb -query | awk '/prompt.color1':'/ { print substr($2,2) }'`

qq=';2;'$( h2d ${COLOR1:0:2} )';'$( h2d ${COLOR1:2:2} )';'$( h2d ${COLOR1:4:2} )'m\]'

COLOR1='\[\033[48'$qq
COLOR2='\[\033[38'$qq

if [ ${EUID:-$(id -u) } -ne 0 ]; then
    COLOR1=${COLOR2}

    # cat /etc/os-release

    hostnamectl
else
    COLOR1=${COLOR1}
fi

export PS1="\n  ${COLOR1}\u${NC}${COLOR2}\h:${NC}\W ${COLOR2}]${NC} "
# --------------------------- PROMPT END

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#trap 'printf "\033]0;%s\007" "${BASH_COMMAND//[^[:print:]]/}"' DEBUG