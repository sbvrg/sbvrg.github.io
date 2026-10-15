# Writing a built-in

Most new words belong in a [root unit](units.md), written in omega, where they can be edited without rebuilding the kernel. A built-in is the right choice when the word needs hardware access that the existing words don't give, or when it has to be fast without relying on the [JIT](jit.md).

## Where built-ins live

Each C file that defines words ends with a table of name and function pairs, terminated by a null entry. At boot the kernel walks every table and stores each function on the interned name ([values and objects](values.md)). Adding a word means writing a function and adding a line to the table of the file it belongs in:

| File | Words |
|---|---|
| `words.c` | stack, math, logic, flow, lists, text, printing, definitions |
| `hw.c` | memory, ports, CPU, PCI, time, screen, keys, tabs |
| `ord.c` | ordinals and cardinals |
| `root.c` | `root`, `open`, `unit`, `src` |
| `persist.c` | drives, saving, installing |
| `jit.c`, `dis.c` | the JIT and the disassembler |
| `help.c` | `help` |

A built-in takes no arguments and returns nothing. It works on the current tab's state through the `W` macro, which points at the running tab's interpreter.

## Taking arguments

Arguments are popped from the stack with helpers that check their count and type and fail the line with a readable message:

    static void b_double(void) {
        i64 n;
        if (!pop_int("double", &n)) return;
        push(I(n * 2));
    }

`pop_int` fails with `double needs more values on the stack` when the stack is empty, `double needs a number` when the top isn't an integer, and `double needs a number that fits in 64 bits` for a bignum. `pop_str` does the same for strings. For other types, check the count with `need` and the tag with `want`.

Arguments come off in reverse order. A word with the stack effect `a b -- c` pops `b` first:

    i64 a, b;
    if (!pop_int("w", &b) || !pop_int("w", &a)) return;

The word's name is passed to each helper only for the error message. Use the name the user types.

## Failing

`fail(fmt, arg)` sets the tab's error flag and message. The format takes exactly one `%s`, so a message without an argument is written as `fail("that went wrong%s", "")`. Only the first failure on a line is kept.

A built-in must return soon after failing. Nothing is unwound for it: the interpreter notices the flag after the built-in returns and stops. Anything the built-in already did outside the stack and dictionary, such as writing to a port, stays done ([transactions](transactions.md)).

Write messages the way the existing ones are written: lowercase, without a trailing full stop, and saying what is wrong in terms the user knows, such as `the tab number has to be 1 to 4`.

## Results

`push` takes a value cell. `I(n)` makes an integer, `S(str_new(p, len))` a string and `Q(quote_new(cells, n))` a quote, which is also how lists are returned. `push` checks for a full stack and does nothing once the line has failed, so a built-in can push several results without checking in between.

## Allocating

Objects for omega values come from the tab's collected heap through the constructors above. They can fail when memory runs out, in which case they set the error and return null, and the built-in should return.

Memory that is not an omega value, such as a scratch buffer, comes from `kmalloc_try` and must be released with `kfree` before returning, including on every failure path. `kmalloc` without `_try` stops the machine with a panic when memory runs out, so it is only used where that is acceptable.

## Calling back into omega

A built-in that runs a quote, as `times` and `map` do, must protect it from the [garbage collector](gc.md). Once the quote is popped, nothing else refers to it, and a collection while it runs would free it. Push it onto the keep stack before calling it and pop it afterwards:

    V q = pop();
    keep(q);
    for (i64 i = 0; i < n && !W->err && !brk(); i++) call(q);
    unkeep(1);

The loop condition also matters. `W->err` stops the loop when the quote fails, and `brk()` makes the loop respond to Ctrl-C. A loop without `brk()` can only be stopped by switching tabs.

## Interrupts

Built-ins run with interrupts on, so another tab can run between any two instructions. Data shared by all tabs, such as the heap, the screen buffers or a device, must be touched with interrupts off:

    u64 f = irq_save();
    /* shared state */
    irq_restore(f);

Keep these sections short, since the timer and keyboard wait for them.

Long waits should yield instead of spinning. Set the tab's `wake_at` or `wait_key` and call `yield()` in a loop, as `sleep` and `waitkey` do, so that the [scheduler](scheduler.md) skips the tab until there is a reason to run it.

## The JIT

A built-in is called from compiled code the same way the interpreter calls it, so most built-ins need nothing special. If the new word should be inlined into compiled code, as `+` and `dup` are, it needs a case in the JIT's inliner, and it must still fall back to calling the built-in when the inline fast path doesn't apply ([JIT](jit.md)).

## Documenting it

Every built-in needs a `help` entry: its group, the stack effect, a description of at most 52 characters and an example that runs. The docs check, `printf '@docs\n' | build/host`, reports a word without an entry and an entry for a word that doesn't exist, and must print `0 problems` ([testing](testing.md)). Add the word to the [all words](all-words.md) page in the website repository as well.

## Testing it

Run `make host` and try the word in the Linux build of the interpreter, then `make stress`, which collects garbage before every word and fills freed memory with `0xDD`, so a missing `keep` shows up at once. Finally boot it in QEMU with `make run`.
