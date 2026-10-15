# README

## What Subverge is

Subverge is an operating system written from scratch, with its own kernel, shell and programs. Software written for Linux or a BSD has to be rewritten in omega to run on it.

The kernel is called **ordinal** and the shell is called **omega**. The idea came from TempleOS, which also has a shell that compiles code and runs everything in ring 0. Subverge took that idea in its own direction, and the [history](history.md) page tells the rest.

## The shell

At the prompt you type [omega](omega.md), a stack language. A few lines look like this:

    2 3 +
    [ dup * ] :sq
    7 sq

The whole system is written in omega, from the [clock](tools.md) to the [installer](installation.md). [First steps](first-steps.md) has a short first session.

## Where to start

Boot the ISO as described in [installation](installation.md) and run `learn`. Afterwards, `help` lists every word, `'dup help` explains one, and `apps` lists the bundled programs.

## How the system behaves

When a line fails, everything it did is undone. This is called a [transaction](transactions.md). Lines that worked can be undone with [back](back.md).

There are four [tabs](tabs.md), switched with F1 to F4. Each has its own [world](world.md), and all four run at the same time.

Programs are kept in [root](root.md), and you can edit them with [scrawl](scrawl.md) while the system is running. An installed system [saves](saving.md) your work after every line.

Infinity is a value in omega, so `omega 1 +` is a valid line ([ordinals](ordinals.md)). The [errors](errors.md) page explains the error messages.

## Raw memory and ports

omega also has words that read and write memory, talk to I/O ports and read PCI configuration space. They are described in [omega for smarties](smarties.md), together with the internals.

## Programs

Subverge comes with [tools](tools.md), [games](games.md) and [demos of infinity](demos.md). They are omega programs, so you can open and change them while the system runs. [Apps](apps.md) explains how to add your own to the list.

## Real hardware

Subverge targets QEMU. If you try it on a real machine, [report](bugs.md) the result. The [hardware](hardware.md) page lists what a real machine needs.

## Problems

Check [troubleshooting](troubleshooting.md) and the [FAQ](faq.md) first. If that doesn't help, [report the problem](bugs.md) with the exact line you typed and the exact error.

## Building

[Development](development.md) describes how to build Subverge from source, [testing](testing.md) how to run omega without booting, and [source layout](source-layout.md) which file does what.

## License

Subverge is released under the GPL v3. See [license](license.md).
