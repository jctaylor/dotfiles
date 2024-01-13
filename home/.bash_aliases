# Alias definitions.

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
# 
alias la='ls -AF'
alias l='ls -CF'
alias cls='clear; ls -CF'
alias clsa='clear; ls -CFA'
alias cll='clear; ls -lF'
alias clla='clear; ls -lFA'
alias ll='ls -lF'
alias lla='ls -AlF'
alias lart='ls -lart'
alias cd='cd -P'
alias g='git status'

alias cd='cd -P'

alias py3='python3'
alias py='python3'


alias gdt='git difftool'
alias g='git status'

