# Testing

## make host

    $ make host

builds the omega interpreter as an ordinary Linux program, `build/host`, from the same source files as the kernel. `test/host.c` provides a fake screen, keyboard and clock, so anything that doesn't need real hardware can be tested without a VM. Lines on standard input are fed to tab 1 one at a time:

    $ printf '1 2 + .\n@screen\n' | build/host

Besides omega, it accepts a few directives:

| Directive | What it does |
|---|---|
| `@screen` | prints the fake 80 by 24 screen |
| `@keys` | queues keys for the next line to read |
| `@roundtrip` | saves the world as source, loads it back and compares |
| `@dis name` | writes a word's compiled code to `build/dis.bin` and the [disassembler](dis.md)'s listing of it to `build/dis.txt` |
| `@docs` | checks `help` against every word that exists |

It is also the quickest way to check what a line does.

## The docs check

    $ printf '@docs\n' | build/host

must print `0 problems`. It reports built-in or root words without a help entry, entries for words that don't exist, entries in unknown groups, and descriptions over 52 characters or stack effects over 15.

## make stress

    $ make stress

builds the host program with the [garbage collector](gc.md) running before every word and freed memory filled with `0xDD`. A missing GC root, which would otherwise fail rarely and at random, shows up immediately as a crash or a value full of `0xDD`. Run it for any change to `kernel/omega.c` or any new built-in.

## make jit-test

    $ make jit-test

boots the real kernel in QEMU and runs `test/jit.qd`, which defines `fib`, benchmarks it with the [JIT](jit.md) on and off, xrays it, then defines an infinite loop, runs it and stops it with Ctrl-C, saving screenshots to `build/`. Compiled `fib` should be clearly faster than interpreted.

## qdrive

`test/qdrive.c` drives a real Subverge in QEMU. It starts QEMU with a monitor socket and no display and runs a script, one command per line:

| Command | What it does |
|---|---|
| `wait ms` | waits |
| `type text` | types text, without Enter |
| `cmd text` | types text, presses Enter, waits 600 ms, or `cmd text  ~2000` to wait 2000 |
| `key name` | presses one key, by QEMU's name for it, like `ret`, `f2` or `ctrl-c` |
| `shot file.png` | takes a screenshot |
| `mon command` | sends a raw QEMU monitor command |
| `quit` | stops |

Lines starting with `#` are comments. Everything after `--` is the QEMU command line to run:

    $ make qdrive
    $ build/qdrive test/shots.qd -- qemu-system-x86_64 -cdrom build/subverge.iso -m 256M

The `test/*.qd` scripts boot it, install it, reboot it and take screenshots along the way.

## Not tested

Real hardware is not tested ([hardware](hardware.md)).
