# Words

The everyday words, grouped as `help` groups them. `'word help` documents any of them. [All words](all-words.md) has the complete table, and [omega for smarties](smarties.md) covers the memory, port, screen, machine and compiler words.

## syntax

`[ ]` [quotes](quotes.md), `:name` definitions, `->name` and `{ a b }` locals, `'name` symbols ([names](names.md)), `"text"` [strings](strings.md), `42 0x2a` [numbers](numbers.md), `#` comments.

## stack

`dup drop swap over rot nip depth empty`. See [stack](stack.md).

## math and logic

`+ - * / mod ^ neg abs min max`, `= < > <= >= and or not`, and bitwise `& | xor ~ << >>`. See [numbers](numbers.md). `+ * ^` also work on [ordinals](ordinals.md).

## flow

`do if when unless times for while each map filter eval trace try`. See [flow](flow.md), and [catching](catching.md) for `try`.

## lists and text

`list range append cat len at first last rest has spread` on [quotes](quotes.md), and `str hex chr slice pad find split >num upper` on [strings](strings.md).

## io

`. say write emit nl color key key? waitkey ask`.

`key` waits for a key and returns its code, `key?` returns `-1` immediately if no key is waiting, and `waitkey` waits up to a given number of ticks. The arrow keys are `256` to `259`, in the order up, down, left, right.

## names

`get forget >sym defined? see words edit`. See [names](names.md).

## world

`help back stats save home root open unit src welcome`. See [help](help.md), [back](back.md), [saving](saving.md), [root](root.md), [units](units.md) and [startup](startup.md).

## infinity

`omega epsilon0 omega1 aleph0 aleph1 aleph continuum card ordinal?`. See [ordinals](ordinals.md) and [cardinals](cardinals.md).

## time

`ticks hz time idle sleep rand`. The timer runs at 100 ticks a second, so `100 sleep` waits one second. In QEMU the clock is UTC unless configured otherwise ([QEMU](qemu.md)).

## tools, demos and games

The programs in root, described in [tools](tools.md), [demos](demos.md) and [games](games.md).

## util

`sq inc dec kb mb uptime >hex fmt attr fill bar header quit-key?`. Small helpers used by the programs, available to yours as well. `quit-key?` is true for `q`, Esc and Ctrl-C, which is why those keys exit almost every program. The drawing helpers are described in [screen](screen.md).

## helpers

Words used internally by the root programs, listed by `'helpers help`. `user`, `host` and `os` are the strings shown on the `sys` screen ([startup](startup.md)).
