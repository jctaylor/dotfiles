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

# Directory listings
alias ls='ls -CF --color=auto'
alias ll='ls -lF --color=auto'
alias lla='ls -AlF --color=auto'
alias la='ls -AF --color=auto'
alias l='ls -CF --color=auto'
alias lart='ls -lArt --color=auto'
alias cls='clear; ls -CF --color=auto'
alias cll='clear; ls -lF --color=auto'

alias cd='cd -P'

# Python
alias py3='python3'
alias py='python3'

# Git
alias gdt='git difftool'
alias g='git status'

