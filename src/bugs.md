# Bugs

## Before reporting

Check `'word help`, [troubleshooting](troubleshooting.md) and the [FAQ](faq.md), and make sure you are on the latest [release](https://github.com/texivi/Subverge/releases). Try it on the live ISO without a disk attached, so that an old saved root isn't involved. If it only happens with your disk, say so in the report.

## Where

Bugs go on the [issue tracker](https://github.com/texivi/Subverge/issues), one bug per issue. For quick questions you can also message `texivi` on Discord. Questions about how a word works are fine there too, after reading its help.

## What to include

- the exact line you typed
- the exact error, or a screenshot
- what you expected to happen
- your QEMU command line, since many boot problems come from a flag
- whether you were on the live ISO or an installed disk, and the version that `sys` shows
- the theme, if the problem is about colours
- whether it happens again after a fresh boot

A screenshot of the QEMU window is often the fastest way to show what happened, since it has the line, the error and the tab bar in one picture. For a crash, include the red message the tab printed before it restarted, which names the CPU exception.

## Not bugs

- Failing on real hardware is expected ([hardware](hardware.md)), though a report is still welcome.
- `omega 1 -` fails because ordinals have no subtraction ([ordinals](ordinals.md)).
- `aleph1 continuum =` fails because ZFC can't decide it ([cardinals](cardinals.md)).
- Subverge isn't POSIX and won't be.
- A line that fails and leaves nothing behind is the [transaction](transactions.md) undoing it.
- A `poke` or `out` that crashes the machine. Ring 0 has no protection against them ([expectations](expectations.md)).

## Patches

Patches are welcome. Make sure the docs check prints `0 problems` and `make stress` passes ([development](development.md)), then open a pull request.
