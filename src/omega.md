# omega

omega is the language you type at the prompt, and every program in Subverge is written in it. It is a concatenative stack language in the Forth tradition. [Words](words.md) covers the everyday vocabulary, and [omega for smarties](smarties.md) the precise rules and the machine-level words.

## Evaluation

    2 3 +           leaves 5
    2 3 + 4 *       leaves 20

Values are pushed onto the [stack](stack.md), and words pop their arguments and push their results. A line is read left to right as whitespace-separated tokens. There is no operator precedence and no parentheses.

## Values

| Type | Written as | More |
|---|---|---|
| integer | `42` `-7` `0x2a` | [numbers](numbers.md) |
| string | `"text"` | [strings](strings.md) |
| quote | `[ 1 2 + ]` | [quotes](quotes.md) |
| symbol | `'name` | [names](names.md) |
| ordinal | `omega` `epsilon0` `omega1` | [ordinals](ordinals.md) |
| cardinal | `aleph0` `aleph1` `continuum` | [cardinals](cardinals.md) |

Comparisons return `1` or `0`, and any non-zero value counts as true. A quote is both a list and a piece of code. `#` starts a comment that runs to the end of the line.

## Definitions

    [ dup * ] :sq
    7 sq            leaves 49

A definition belongs to your tab's [world](world.md). Words that every tab should see go in [root](root.md). Locals are dynamically scoped, as described in [names](names.md).

## Control flow

    x 0 > [ "yes" ] [ "no" ] if say
    10 [ "again" say ] times
    0 10 [ . ] for

Conditionals and loops are ordinary words that take quotes. [Flow](flow.md) lists them, along with `trace` for stepping through code.

## Errors

A failing word undoes the whole line ([transactions](transactions.md)). `try` lets a line continue past a failure ([catching](catching.md)), and [errors](errors.md) explains the messages.

## Help

`help` lists every word, `'group help` lists one group and `'word help` documents one word.
