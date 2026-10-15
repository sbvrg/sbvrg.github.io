# Saving

The live ISO saves nothing: `save` fails and `home` returns `-1`. To keep your work, [install](installation.md) Subverge to a disk image.

An installed system saves automatically after each line that changes the world, each root edit that builds and each `back`. `save` writes everything immediately. `home` returns the number of the drive Subverge is installed on.

## Slots

An installed disk has five slots of 1 MiB. Slot 0 is [root](root.md), and slots 1 to 4 are the [tabs](tabs.md). Only the tab that changed gets rewritten.

## What's in a slot

A slot holds plain omega source. A tab is saved as its definitions, oldest first, followed by its stack:

    # saved world
    [ dup * ] :sq2
    [ { a b } a a * b b * + ] :hyp
    1 2 3

Root is saved as each unit's source after its `#>> name` line. At boot each slot is run as if it had been typed.

Only values that can be written as source survive. Integers, strings, quotes, symbols, ordinals and cardinals do. Memory from `alloc` doesn't, so a saved address is meaningless after a reboot.

## Not saved

The `back` history, the prompt history, tab titles, the screen contents and raw memory are not saved.

## Damaged slots

A slot whose checksum doesn't match is treated as empty, and that tab boots fresh. A damaged root slot falls back to the kernel's built-in root.

A world or root larger than 1 MiB is silently not saved.
