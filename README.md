# podman-fleet

Just a basic script to quickly spawn a fleet of custom podman containers with persistent volumes.

## WORK IN PROGRESS

This is possibly the most broken and inefficient script you have ever seen, but I needed a quick script that spawned several containers, without the need to install a proper orchestrator.

This was meant to stay trivial and not become so advanced that it overlaps in function other utilities that do similar things, but work is still needed to make this more generalized and more intelligent if it's going to stay on GitHub. 


## TODO

- Cleanup function
- Attach function
- Start function
- Stop function
- SSH connections


## Tmux cheat sheet: 
| Shortcut          |   Description |
| ------------------|---------------|
| CTRL+B N          | [N]ext window |
| CTRL+B P          | [P]revious window |
| ------------------|---------------|
| CTRL+B D          | [D]etach |
| tmux a            | Attach to last session |
| tmux ls           | List sessions |
| tmux a -t MY1     | Attach to tmux session named MY1 |
| ------------------|---------------|
| CTRL+B C          | New window | 
| CTRL+B "          | Split vertically | 
| CTRL+B %          | Split vertically | 

To interact with nested tmuxes on the hosts, use CTRL+B+B
