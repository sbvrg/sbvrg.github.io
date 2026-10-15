# back

`back` undoes the last line that changed the world. Up to 64 lines can be undone.

![back](images/07-back.png)

Lines that changed nothing, such as `words`, `help` or a failed line, aren't recorded, so `back` skips them.

## Several at once

    back back back

rewinds three lines. Everything else on a line containing `back` is discarded, so `[ 1 ] :x back` doesn't define `x`.

## Scope

`back` restores the stack and the tab's definitions, the same state a [transaction](transactions.md) protects. Root edits, printed text, other tabs and anything written to memory, a port or the screen are not affected, so `back` can't undo a `poke`.

## On an installed disk

A rewind is saved like any other change, but the history isn't, so after a reboot `back` has nothing to return to ([saving](saving.md)).

The Up arrow at the [prompt](prompt.md) recalls the text of a line, not its effect.
