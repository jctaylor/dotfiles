# Alias definitions.

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto -F'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF --color=always'
alias la='ls -AF --color=always'
alias lart='ls -lart --color=always'
alias l='ls -CF --color=always'
alias ls='ls -CF --color=always'
alias py3='python3'
alias py='python3'
alias gdt='git difftool'
alias cd='cd -P'
alias g='git status'
alias venv-on='source venv-activate.sh'
alias venv-off='deactivate'

# Mac work computer
alias ugr='ssh ubuntugr -t /home/jason/.local/bin/tmux-notes.sh'


