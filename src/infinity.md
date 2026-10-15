# How infinity works

How omega stores and calculates with ordinals and cardinals. Read [ordinals](ordinals.md) and [cardinals](cardinals.md) first.

## Cantor normal form

Every ordinal below `epsilon0` can be written in exactly one way as a sum of powers of omega, biggest first, each multiplied by a whole number:

    ω^a·c + ω^b·d + ...

omega keeps ordinals in this form. `omega 2 * 3 +` is `ω·2+3`, and the exponents can be ordinals too, as in `omega omega ^`. `epsilon0` and `omega1` can't be written this way, so omega treats them as two special values that are bigger than all of these.

## Comparing

Two ordinals are compared from the front. The one with the bigger first exponent is bigger. If those are equal, the bigger number in front of it wins, and if that's equal too, the next part decides.

## Adding

When you add `a` and `b`, every part of `a` that is smaller than the first part of `b` disappears. So `1 omega +` is `omega`, because `1` is smaller than `omega`, while `omega 1 +` keeps both and is `ω+1`.

## Multiplying and powers

`a b *` is `a` repeated `b` times. Multiplying by a whole number only changes the front of `a`, so `omega 1 + 2 *` is `ω·2+1`. Multiplying by something infinite adds to the exponent instead, so `2 omega *` is `omega` and `omega omega *` is `ω²`.

Powers follow from multiplying. A whole number to an infinite power gives a power of omega, so `2 omega ^` is `omega`. Very large exponents fail with `that exponent is too big to write out`.

## Limits

An ordinal can have up to 64 parts, and the numbers in front of each part have to fit in 64 bits.

## Cardinals

A cardinal is either an aleph or two to the power of an aleph. Adding or multiplying two of them gives the bigger one. `2 aleph0 ^` is the size of the power set, and `aleph0 3 ^` is `aleph0`. Other powers fail.

Comparing alephs with powers of two only goes as far as set theory does. `aleph1 continuum <=` is `1`, but whether they are equal is the continuum hypothesis, which can't be proved or disproved, so `aleph1 continuum =` fails with the ZFC error. `aleph2 continuum <` fails the same way.

## Printing and saving

Ordinals and cardinals print with real ω and ℵ characters, which the kernel adds to the [screen](screen.md) font. When a tab is [saved](saving.md), they're written as omega code instead, so `ω·2+3` is saved as `omega 2 * 3 +`.
