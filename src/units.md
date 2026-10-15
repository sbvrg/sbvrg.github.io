# Units

A unit is a named part of [root](root.md). Your own unit is the place for words that every tab should see and that should survive reboots.

    "mine" unit

This creates an empty unit at the end of root and opens it in [scrawl](scrawl.md). Write `[ "hi" say ] :greet`, save with Ctrl-S and quit with Ctrl-Q, and `greet` is available in every [tab](tabs.md).

![Making a new unit](images/52-new-unit.png)

![root with the new unit in it](images/53-root-mine.png)

## Rules

Unit names are 1 to 20 characters of lowercase letters, digits and `-`, and must be unique. Root can hold up to 32 units.

## Order

New units are always added at the end, so they can use every other unit and editing one only rebuilds itself. Reordering or removing units requires changing `root/` in the source tree and rebuilding the kernel ([development](development.md)). From inside the system, a unit can only be emptied.

A later unit overrides an earlier one that defines the same word, and redefining a built-in prints a `shadows:` warning. All of root has to fit in one 1 MiB [slot](saving.md). A program also needs an entry in the [apps](apps.md) list to appear there.
