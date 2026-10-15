# Quotes

A quote is code in square brackets that is pushed rather than run. It is also a list, and the same value can be used either way. [Flow](flow.md) describes the words that run quotes.

## Quotes as code

    [ 1 2 + ]           pushes a quote, adds nothing
    [ 1 2 + ] do        leaves 3

`if`, `times` and the other control words are ordinary words that take quotes and decide when to run them. A defined word is a quote bound to a name:

    [ dup * ] :sq

## Quotes as lists

    [ 1 2 + ] len .             3
    [ 1 2 + ] 2 at .            '+

Inside a quote a word is stored as its name, so the `+` comes back as the symbol `'+`. Quotes can hold any value, including other quotes.

## The list words

| Word | Effect | |
|---|---|---|
| `list` | `... n -- l` | packs the top n values |
| `range` | `a b -- l` | a up to b-1 |
| `append` | `l x -- list` | x on the end |
| `cat` | `a b -- c` | joins two lists |
| `len` | `l -- n` | how many items |
| `at` | `l i -- x` | item i, from 0 |
| `first` | `l -- x` | the first item |
| `last` | `l -- x` | the last item |
| `rest` | `l -- list` | all but the first |
| `has` | <code>l x -- 1&#124;0</code> | is x in it |
| `spread` | `l -- ...` | every item onto the stack |

Lists are immutable, so these words return new lists and leave the original untouched.

## Iterating

    [ 1 2 3 ] [ . ] each
    [ 1 2 3 ] [ 2 * ] map           [ 2 4 6 ]
    1 11 range [ 2 mod 0 = ] filter [ 2 4 6 8 10 ]

The quote given to `map` must leave exactly one value per item.

## Limits

Quotes that are too long, nested too deeply or unbalanced fail with their own messages, listed in [errors](errors.md).
