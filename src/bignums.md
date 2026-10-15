# Bignums

How omega handles integers that don't fit in 64 bits. For the basics, read [numbers](numbers.md) first.

## Small and big

A number that fits in 64 bits is kept as a plain machine integer. When a result gets bigger than that, it becomes a bignum by itself, and when a result fits again, it goes back to being a plain integer. `2 64 ^ 2 64 ^ -` is a plain `0`. Code that only uses small numbers never pays for bignums.

## The limit

A bignum can have up to 65,536 bits, so the biggest number is just under 2^65536. A result that would be bigger fails with `that number is too big, the limit is 2^65536` before any work is done, so `2 100000 ^` fails straight away instead of hanging.

Printing a very big number takes a moment. `2 65536 ^ .` prints about 19,700 digits.

## Where they work

Arithmetic, comparisons, `str`, `>num`, conditions and saving all take bignums. `/` rounds toward zero and `mod` takes the sign of the left number, the same as with small numbers.

Words that need a machine number, like `times`, `at`, `peek` and the bitwise words, fail with `foo needs a number that fits in 64 bits`.

With ordinals, a bignum works on the left, where it disappears anyway: `2 100 ^ omega +` is `omega`. On the right it fails with `that number is too big to mix with an ordinal that way`.

## Bignums and the JIT

Compiled code does `+`, `-`, `*` and `neg` in registers. When a result overflows, it falls back to the normal word, which makes the bignum, so compiled code gives the same answers as the interpreter. See the [JIT](jit.md) page.
