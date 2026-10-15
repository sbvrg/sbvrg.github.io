# Demos

Programs that demonstrate omega's infinite values, plus a Mandelbrot renderer. They assume [ordinals](ordinals.md) and [cardinals](cardinals.md).

## count

Counts through the finite numbers and on past them: omega, omega plus one, omega squared, towers of omegas, `epsilon0` and finally `omega1`, whose cardinality is `aleph1`. It ends with the continuum hypothesis.

![count](images/17-count.png)

## ord-demo

Ordinal and cardinal arithmetic, one line at a time. `1 + w = w` next to `w + 1 = w+1` shows that ordinal addition isn't commutative.

![ord-demo](images/18-ord-demo.png)

## pairing

Pairs the natural numbers with the even numbers one to one, showing that both sets have the same size.

![pairing](images/21-pairing.png)

## diagonal

Cantor's diagonal argument. It flips the diagonal of a list of binary rows to build a row that can't appear in the list, proving that `2 aleph0 ^` is larger than `aleph0`.

![diagonal](images/19-diagonal.png)

## supertask

Halves a line repeatedly until the screen runs out of resolution, illustrating infinitely many steps with a finite total.

![supertask](images/20-supertask.png)

## powerset

    [ 1 2 ] powerset .

Returns every subset of a list. n items give 2^n subsets.

## mandel

The Mandelbrot set in text mode, zooming in on each key press. It uses fixed point with 65536 as 1.0. `mandel-at` draws a single view:

    -32768 0 2816 40 mandel-at

Its inner loop, `mb-iter`, is almost pure arithmetic, which is where the [JIT](jit.md) helps most. `'mb-iter xray` shows the compiled code.

![mandel](images/37-mandel-1.png)

![mandel, further in](images/38-mandel-2.png)

The demos are short, and `'count see` or `'diagonal see` show real code using the ordinal words.
