# README

## What Subverge is

Subverge is an operating system written from scratch, with its own kernel, shell and programs. It is a hobby project. It boots in QEMU into a text screen with four tabs, and the prompt in each tab is a programming language.

The kernel is called **ordinal** and the shell is called **omega**. The idea came from TempleOS, which also has a shell that compiles code and runs everything in ring 0. The infinite values came from Vsauce's video [How To Count Past Infinity](https://www.youtube.com/watch?v=SrU9YDoXE88). For the rest, see [history](history.md).

## The shell

At the prompt you type [omega](omega.md), a stack language. A few lines look like this:

    2 3 +
    [ dup * ] :sq
    7 sq

The programs that come with the system, such as the [clock](tools.md) and the [installer](installation.md), are written in omega. For a short first session, see [first steps](first-steps.md).

## Where to start

Boot the ISO as described in [installation](installation.md) and run `learn`. Afterwards, `help` lists every word, `'dup help` explains one, and `apps` lists the bundled programs.

## How the system behaves

When a line fails, everything it did is undone. This is called a [transaction](transactions.md). Lines that worked can be undone with [back](back.md), up to 64 of them, and `redo` reverses a `back`. Mistakes at the prompt rarely need more than one of these.

There are four [tabs](tabs.md), switched with F1 to F4. Each has its own [world](world.md), and all four run at the same time.

Programs are kept in [root](root.md), and you can edit them with [scrawl](scrawl.md) while the system is running. An edit only takes effect if it builds, so a broken edit can't break the running system. An installed system [saves](saving.md) your work after every line, so it has no save command you need to remember and nothing to lose when QEMU is closed.

Infinity is a value in omega, so `omega 1 +` is a valid line and prints `ω+1` ([ordinals](ordinals.md)). Integers grow past 64 bits by turning into bignums ([numbers](numbers.md)). For error messages, see [errors](errors.md).

## Raw memory and ports

omega also has words that read and write memory, talk to I/O ports and read PCI configuration space. Everything runs in ring 0, so these work directly from the prompt and nothing stops a bad write. See [omega for smarties](smarties.md) for them and the internals, including how the JIT, the garbage collector and the scheduler work.

## Programs

Subverge comes with [tools](tools.md), [games](games.md) and [demos of infinity](demos.md). They are omega programs, so you can open and change them while the system runs. To add your own to the list, see [apps](apps.md).

## Real hardware

Subverge targets QEMU. If you try it on a real machine, [report](bugs.md) the result. For what a real machine needs, see [hardware](hardware.md).

## Problems

Check [troubleshooting](troubleshooting.md) and the [FAQ](faq.md) first. If that doesn't help, [report the problem](bugs.md) with the exact line you typed and the exact error.

## Building

To build Subverge from source, see [development](development.md). It also covers the tests and which file does what.

## License

[GPL v3](https://www.gnu.org/licenses/gpl-3.0.html).
