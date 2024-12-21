#  tmux Cheat Sheet

## Commands

tmux ls
    List tmux sessions

tmux new -s [session]
    Create a new session

tmux attach -t [session]
    Attach to an existing session

tmux rename-session -t [current] [new]
    Rename a session

## Controls

| Prefix ...    | action       |
|---------------|--------------|
| :             | command mode |
| d             | detach       |
| =             | list         |
| pgUp          | buffer view  |
| pgDown        | buffer view  |
| [ space enter | copy         |
| ]             | paste        |

## Sessions

| Prefix |     action    |
|--------|---------------|
| $      | rename        |
| s      | list sessions |
| (      | next          |
| )      | previous      |


## Windows

| Prefix   | action   |
|----------|----------|
| w        | List     |
| c        | Create   |
| , [name] | Rename   |
| l        | Last     |
| &        | Close    |
| [0-9]    | Goto #   |
| n        | Next     |
| p        | Previous |
| w [name] | Choose   |

## Panes

| Prefix       | action       |
|--------------|--------------|
| q            | show ID      |
| "            | split Horiz  |
| %            | split Vert   |
| !            | pane-]window |
| x            | kill         |
| [space]      | reorganize   |
| [alt][arrow] | expand       |
| ^[arrow]     | resize       |
| [n] [arrow]  | resize x n   |
| [arrow]      | select       |
| {            | previous     |
| }            | next         |
| o            | switch       |
| ^o           | swap         |
| ;            | last         |
                                             
