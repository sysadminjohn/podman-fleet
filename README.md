# podman-fleet

Just a basic script to quickly spawn a fleet of custom podman containers with persistent volumes.

## WORK IN PROGRESS

This is possibly the most broken and inefficient script you have ever seen, but I needed a quick script that spawned several containers, without the need to install a proper orchestrator.

This was meant to stay trivial and not become so advanced that it overlaps in function other utilities that do similar things, but work is still needed to make this more generalized and more intelligent if it's going to stay on GitHub. 

## TODO

As a bare minimum, this script needs to be split into functions, so that you can for example call it with `spawn` or `attach` or `cleanup` parameters, then the podman creation string needs to be split in a more intelligent way.

The SSH implementation is not working yet, so it's due for a either a fix or a removal since it shouldn't be needed in first place.