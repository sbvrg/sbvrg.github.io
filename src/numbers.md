# Numbers

omega's finite numbers are exact integers up to 2^65536. Infinite values are covered in [ordinals](ordinals.md).

## Literals

    42   -7   0x2a   0b101

Integers can be written in decimal, in hex with `0x` or in binary with `0b`. `bases` shows a number in decimal, hex, octal and binary ([tools](tools.md)).

## Arithmetic

| Word | Effect | |
|---|---|---|
| `+` | `a b -- c` | adds |
| `-` | `a b -- c` | subtracts |
| `*` | `a b -- c` | multiplies |
| `/` | `a b -- c` | divides, rounding toward zero |
| `mod` | `a b -- r` | remainder |
| `^` | `a b -- c` | a to the power b |
| `neg` | `a -- -a` | flips the sign |
| `abs` | `a -- b` | drops the sign |
| `min` `max` | `a b -- c` | the smaller or bigger |

## Truth

Comparisons leave `1` or `0`, and any non-zero value counts as true.

`and` and `or` are logical while `&` and `|` are bitwise, so `12 10 and` is `1` but `12 10 &` is `8`.

## Big numbers

Integers never wrap. A result that doesn't fit in 64 bits becomes a bignum automatically:

    2 100 ^ .                   1267650600228229401496703205376
    2 1000 ^ str len .          302

Bignums work with arithmetic, comparisons, `str`, `>num`, conditions and saving. Words that need a machine integer, such as `times`, `at`, `peek` and the bitwise words, fail with `foo needs a number that fits in 64 bits`.

The limit is 2^65536, about 19,700 digits. Larger results fail with `that number is too big, the limit is 2^65536`. [Bignums](bignums.md) describes how they are handled.

## Division

`/` truncates toward zero and `mod` takes the sign of the dividend, so `-7 2 mod` is `-1` and an odd test written as `2 mod 1 =` is wrong for negative numbers. Division by zero fails, and `^` doesn't accept negative exponents.

## Conversion and random numbers

`str`, `hex`, `>hex` and `>num` convert to and from strings ([strings](strings.md)). `6 rand` returns a number from 0 to 5.

## Floating point

omega has no floating point. The unit conversions in [tools](tools.md) work in hundredths, and `mandel` uses fixed point with 65536 as 1.0.
