# Strings

Strings are immutable byte sequences written in double quotes. Words that appear to modify a string return a new one.

## Literals

    "hello"
    "two\nlines"
    "a \"quoted\" word"

The escapes are `\n \t \e \\ \"`, plus `\w` for omega and `\A` for aleph.

## Printing

    "hi" say        hi, then a new line
    "hi" write      hi, no new line
    "hi" .          "hi"

`color` sets the text colour from 0 to 15, and `colors` shows the palette.

## String words

| Word | Effect | |
|---|---|---|
| `cat` | `a b -- c` | joins two strings |
| `len` | `s -- n` | length in bytes |
| `at` | `s i -- n` | the character code at i |
| `slice` | `s a n -- str` | n characters from a |
| `find` | `s sub -- i` | where sub starts, or -1 |
| `split` | `s sep -- l` | cuts into a list |
| `upper` | `s -- str` | capitals |
| `pad` | `s n -- str` | pads to n wide, negative pads left |
| `str` | `v -- s` | any value as a string |
| `>num` | `s -- n` | reads a number |
| `hex` | `n -- s` | hex without `0x` |
| `chr` | `n -- s` | a character from its code |

There is `upper` but no `lower`.

## Details

`at` and `each` return character codes, so `"hello" 1 at` is `101`. `chr` converts a code back to a string.

`slice` past the end returns a shorter string instead of failing. `split` keeps empty fields, so `"a,b,,c" "," split` has four items.

`=` compares strings, but `<` and `>` only accept numbers, so string ordering has to be written by hand.

## eval

    "1 2 +" eval        leaves 3

`eval` parses and runs a string in the current context, with the same ring 0 access as any other code.

## Input and formatting

`ask` prints a prompt and reads a line. `fmt` and `pad` align columns, and `kb` and `mb` format byte counts.
