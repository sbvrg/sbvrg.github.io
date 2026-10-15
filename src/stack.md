# Stack

Each tab has one data stack. Words take their arguments from it and leave their results on it, and it is the only way to pass values between words.

## Pushing and popping

    1 2 3
    +

Literals are pushed on top. `+` pops `3` and `2` and pushes `5`, leaving `1 5`. A word that finds too few values fails.

## Stack effects

    ( a b -- c )

A stack effect lists what a word takes and what it leaves, with the top of the stack on the right. `dup` is `( a -- a a )`. `'word help` shows the effect of any word.

## Stack words

| Word | Effect | |
|---|---|---|
| `dup` | `a -- a a` | copies the top value |
| `drop` | `a --` | discards it |
| `swap` | `a b -- b a` | swaps the top two |
| `over` | `a b -- a b a` | copies the second to the top |
| `rot` | `a b c -- b c a` | moves the third to the top |
| `nip` | `a b -- b` | drops the second |
| `depth` | `-- n` | the number of values |
| `empty` | `... --` | clears the stack |

Long chains of `swap rot over` are hard to read. Locals usually do the job better ([names](names.md)).

## Inspecting it

`.` prints the top value as source and `say` prints it as text, and both pop it. To print the whole stack without changing it:

    depth list dup . spread

## Limits

The stack holds 1024 values, after which pushing fails with `the stack is full`. This usually means a loop that pushes without popping. Popping an empty stack fails with `drop needs more values on the stack`, naming whichever word it was.

The stack is part of the tab's [world](world.md), and each [tab](tabs.md) has its own.
