# First steps

A short first session. For booting, see [installation](installation.md).

## The prompt

`»` is the omega prompt, and each line you type is an omega program. There is no other command language.

    2 3 +           leaves 5 on the stack
    .               prints and drops it

Arguments come first and the operator last, as in Forth. See [stack](stack.md).

## learn

`learn` is a series of one-screen lessons, each with a line to try. Space goes on, `b` goes back and `q` quits. Lessons count from 0, so `14 lesson` starts at the fifteenth. [learn](learn.md) lists them.

## Lines to try

`empty` clears the stack.

    2 3 + 4 *                 20
    [ dup * ] :sq             defines sq
    7 sq .                    prints 49
    10 [ "hi" say ] times     prints hi ten times
    0 5 range .               [ 0 1 2 3 4 ]
    [ 1 2 3 ] [ sq ] map .    [ 1 4 9 ]
    "subverge" upper say      SUBVERGE
    1 0 /                     fails, and the line is undone
    omega 1 + .               w+1

The last one is ordinal arithmetic ([ordinals](ordinals.md)).

## Finding words

    help                every word, by group
    'math help          one group
    'map help           one word

`apps` lists the programs and `root` lists the units that define them.

## Mistakes

A failing line is undone and its error is printed in red ([transactions](transactions.md)). `back` undoes lines that succeeded, up to 64 of them ([back](back.md)). Ctrl-C interrupts whatever is running.

## Tabs

F1 to F4 switch between four [tabs](tabs.md), each with its own stack and definitions, all running concurrently. A `*` after a tab's name means it has printed something you haven't seen.

## Next

[omega](omega.md) covers the language, [tools](tools.md) and [games](games.md) the bundled programs, [startup](startup.md) the boot greeting and [prompt](prompt.md) the line-editing keys.
