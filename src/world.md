# World

A world is the [stack](stack.md) and the definitions ([names](names.md)) of one [tab](tabs.md). Root, locals, the screen and the machine aren't part of it.

Each successful line produces a new world, and the last 64 are kept for [back](back.md). A failing line leaves the world untouched ([transactions](transactions.md)). [How worlds work](worlds.md) explains the mechanism.

An installed disk [saves](saving.md) each world. Tabs share only [root](root.md), so definitions don't leak between them.

## Inspecting it

`words` lists the definitions and `depth list .` prints the stack. `stats` reports the object count, collections, definitions, stack depth and history length.

![stats, heap and disks](images/65-stats-disks.png)
