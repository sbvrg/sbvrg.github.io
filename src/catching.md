# Catching

`try` runs a quote and keeps a failure inside it from aborting the line. It leaves `1` if the quote completed, or prints the error and leaves `0` if it failed.

    [ 1 0 / ] try .         prints the error, then 0

## No rollback

`try` doesn't roll anything back:

    [ 5 6 0 / ] try

leaves `5 0`. The `5` was pushed before the failure and stays, and the `0` comes from `try`. Only the line as a whole is a [transaction](transactions.md).

Restoring the stack after a failure is up to you. `learn` does it by saving the stack with `depth list` before each line and spreading it back when `try` leaves `0` (`'learn open`).

## Interrupts

Ctrl-C raises `interrupted`, which is an ordinary error, so `try` catches it:

    [ 1000000000 [ ] times ] try "after" say

Pressing Ctrl-C there prints `! interrupted` and then `after`. The `stopped` error from `trace` is caught the same way.

## Limits

`try` can't catch a CPU fault, which restarts the tab, or `halt`.

## Use

Use `try` for failures you expect:

    "12x" [ >num ] try [ "number" say ] [ "not a number" say ] if

Wrapping code in `try` defensively makes failures harder to find, since a line that fails outright is easier to debug than one that continues with a damaged stack. The messages are listed in [errors](errors.md).
