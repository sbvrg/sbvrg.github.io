# Transactions

Each line you type runs as a transaction on your tab's [world](world.md). Either all of it happens or none of it does.

    1 2 3
    [ 7 ] :seven 4 5 0 /

The division fails, so `seven` is not defined, `4 5` is not pushed, and the stack is still `1 2 3`.

![A line failing and taking everything with it](images/05-ordinals-and-errors.png)

## Scope

Transactions only cover the tab's stack and definitions. These are outside them:

- **Printed text**, which stays on screen.
- **Root**, whose edits are rebuilt with their own all-or-nothing rule ([root](root.md)).
- **The machine.** Memory, ports, `alloc` and direct screen writes take effect when the word runs ([omega for smarties](smarties.md)).
- **The disk**, which is only written after a line succeeds.

## Lines that change nothing

A line that leaves the stack and definitions unchanged, such as `words` or `"hi" say`, is not recorded or saved, and `back` skips over it.

## Continuing after a failure

`try` lets a line continue past a failing quote. [Catching](catching.md) describes what survives.

## Faults

A CPU fault restarts the tab, prints the fault and reports `your last line was dropped`. The world is unaffected, since the line never committed.

[How worlds work](worlds.md) describes the commit in detail.
