# Ordinals

omega supports transfinite ordinals as ordinary values. `omega` pushes the first infinite ordinal, which can be added, multiplied, exponentiated and compared. Cardinals are covered in [cardinals](cardinals.md).

## What an ordinal is

An ordinal describes a position in a well-ordered sequence. The finite ordinals are the natural numbers, and `omega` is the first ordinal greater than all of them.

After `omega` come `omega+1`, `omega+2` and eventually `omega·2`, then `omega²`, `omega^omega`, towers of omegas and, above all of those, `epsilon0`. `omega1`, the first uncountable ordinal, lies beyond every countable one. The `count` demo ([demos](demos.md)) walks up this sequence.

## Literals

    omega           the first infinite ordinal, printed w
    epsilon0        the first ordinal where omega^x = x, printed e0
    omega1          the first uncountable ordinal, printed w1

On the Subverge screen they are printed with a real `ω`. Non-negative integers act as finite ordinals when combined with one.

## Arithmetic

`+`, `*` and `^` are supported, and none of them is commutative:

    1 omega + .         w
    omega 1 + .         w+1

Adding one element before an infinite sequence leaves its order type unchanged, while adding one after it produces a longer one. Multiplication behaves the same way:

    2 omega * .         w
    omega 2 * .         w.2

Powers:

    2 omega ^ .         w
    omega 2 ^ .         w², printed with a superscript inside Subverge

Results are kept in Cantor normal form, a sum of decreasing powers of omega, so `omega 2 * 3 +` prints as `w.2+3`. [How infinity works](infinity.md) describes the representation.

## Unsupported operations

Subtraction, division and negative ordinals are not supported:

    omega 1 -           fails: ordinals only support + * and ^
    omega -3 +          fails: ordinals are never negative

## Comparison

Comparisons follow the ordinal order:

    5 omega < .                 1
    omega omega 1 + < .         1
    epsilon0 omega1 < .         1
    omega epsilon0 ^ epsilon0 = .   1

The last line is the defining property of `epsilon0`.

## Cardinality

`ordinal?` is `1` for infinite ordinals. `card` returns the cardinality of an ordinal as a [cardinal](cardinals.md), so `omega 2 * card` is `aleph0` and `omega1 card` is `aleph1`.
