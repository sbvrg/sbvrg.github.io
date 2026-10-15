# Help

`help` is the manual inside Subverge. Each word has an entry with its stack effect, a short description and an example.

    help                every word, by group
    'math help          one group
    'map help           one word

Without the quote mark, `map` runs instead of being passed to `help`.

![help on its own](images/02-help-overview.png)

![help for one word](images/04-help-word.png)

## The groups

syntax, stack, math, logic, flow, lists, text, io, names, world, infinity, memory, ports, time, screen, machine, dev, tools, demos, games, util and helpers. See [words](words.md) for the everyday ones and [all words](all-words.md) for all of them.

## Your own words

Your own words have no entries, and `'foo help` says so. Document them with `#` comments.

## Other help

[learn](learn.md) is the guided tutorial and [apps](apps.md) lists the programs. `see` prints a word's definition ([names](names.md)).
