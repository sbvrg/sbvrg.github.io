# Cardinals

Cardinals measure the size of a set, where [ordinals](ordinals.md) measure position in an ordering. The two agree for finite sets and differ for infinite ones, so omega keeps them as separate types.

## Literals

    aleph0          the size of the natural numbers, printed A0
    aleph1          the next size up, A1
    3 aleph         the third one, A3
    continuum       the size of the real numbers, 2^A0

On the Subverge screen, `A` is printed as a real aleph.

## Arithmetic

`+`, `*` and `^` are supported. Sums and products of infinite cardinals are simply the larger of the two:

    aleph0 aleph0 + .       A0
    aleph0 aleph0 * .       A0
    3 aleph0 + .            A0
    aleph0 aleph1 + .       A1

Powers are more interesting:

    2 aleph0 ^ .            2^A0
    2 aleph0 ^ continuum = .    1

2^aleph0 is the cardinality of the power set of the naturals, which is also that of the reals. The `diagonal` demo ([demos](demos.md)) shows Cantor's proof that it exceeds `aleph0`:

    aleph0 2 aleph0 ^ < .   1

Some powers, like `aleph0 aleph0 ^`, fail with `that cardinal power isn't supported`.

## The continuum hypothesis

The continuum hypothesis asks whether `aleph1` equals `continuum`, that is, whether any cardinality lies strictly between the naturals and the reals.

    aleph1 continuum =

fails with

    ZFC can't decide this one (continuum hypothesis, Godel 1940 and Cohen 1963)

because it is independent of ZFC. Gödel showed in 1940 that ZFC can't disprove it, and Cohen showed in 1963 that it can't prove it either. omega doesn't assume an answer, so every comparison that depends on it fails the same way. Comparisons that don't depend on it work:

    aleph1 continuum <= .   1

This holds whichever way the hypothesis goes.

## Ordinals and cardinals

Ordinals and cardinals can't be combined directly. Convert an ordinal with `card` first:

    omega 2 * card .        A0
    omega1 card .           A1

Operations other than `+ * ^` fail ([errors](errors.md)).
