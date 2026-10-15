# Flow

Conditionals and loops are ordinary words that take [quotes](quotes.md).

## Choices

    cond [ then ] [ else ] if
    cond [ then ] when
    cond [ then ] unless

Any non-zero condition is true. Nothing checks that both branches of an `if` leave the same number of values, so an unbalanced `if` shows up as a stack error later on.

## Loops

    n [ body ] times
    a b [ body ] for                i from a to b-1, on the stack
    [ test ] [ body ] while

    0 3 [ . ] for                   prints 0 1 2
    0 [ dup 3 < ] [ 1 + ] while     leaves 3

The `while` test must be a quote. Passing `x 3 <` instead of `[ x 3 < ]` evaluates the test once, so the loop either never runs or never ends.

## Walking lists

    list [ f ] each
    list [ f ] map
    list [ f ] filter

On a string, `each` gives character codes ([strings](strings.md)).

## Stopping

Ctrl-C interrupts any loop. The line fails with `interrupted` and is undone along with any partial result, unless the loop is inside `try` ([catching](catching.md)).

## Tracing

    [ 1 2 + 4 * ] trace

`trace` runs a quote one word at a time and shows the stack after each. Space steps, `c` runs the rest and `q` stops. It is the nearest thing omega has to a debugger.

![trace](images/06-trace.png)

`timeit`, `bench` and `watch` time and repeat quotes ([tools](tools.md)).

## Recursion

    [ { n } n 1 > [ n 1 - fib n 2 - fib + ] [ n ] if ] :fib
    20 fib .                6765

Each level binds its own `n`, and only 256 locals can be live at once, so this fails around 256 levels deep with `too many local names`. Deep iteration should use a loop instead.
