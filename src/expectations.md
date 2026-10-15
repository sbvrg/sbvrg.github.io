# Expectations

## It is an experiment

Subverge is experimental and targets QEMU, the only machine it is tested on ([hardware](hardware.md)).

## It is its own system

Subverge has its own kernel, shell and programs, and an installed disk holds fixed slots instead of files ([disk layout](disk-layout.md)). Shell scripts and programs from Linux or a BSD have to be rewritten in omega.

## You need to know how to program

These docs and `learn` assume you already program, and they don't explain loops, variables or functions. Some familiarity with Forth or another stack language helps.

## You can break it

Everything runs in ring 0, so a bad write to memory can bring down the whole virtual machine. Most mistakes cost nothing, because a failing line is undone and [back](back.md) can rewind the last 64 lines. Writes to raw memory and I/O ports can't be undone, and they are your responsibility. Those words are covered in [omega for smarties](smarties.md).

## Never install to a real disk

`install` erases the drive you give it. Only use it on a disk image made for that purpose.

## Asking for help

Run `learn` and read `'word help` before you ask how a word works. When you ask, give the exact line, the exact error and what you expected to happen. [Troubleshooting](troubleshooting.md) and [bugs](bugs.md) have more on this.

## Roadmap

Subverge has no roadmap. Features are added when they are ready, and releases have no dates.

Continue with [installation](installation.md).
