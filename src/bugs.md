# Bugs

## Before reporting

Check `'word help`, [troubleshooting](troubleshooting.md) and the [FAQ](faq.md), and make sure you are on the latest [release](https://github.com/texivi/Subverge/releases).

## Where

Bugs go on the [issue tracker](https://github.com/texivi/Subverge/issues). For quick questions you can also message `texivi` on Discord.

## What to include

- the exact line you typed
- the exact error, or a screenshot
- what you expected to happen
- your QEMU command line, since many boot problems come from a flag
- whether you were on the live ISO or an installed disk, and which version
- whether it happens again after a fresh boot

## Not bugs

- Failing on real hardware is expected ([hardware](hardware.md)), though a report is still welcome.
- `omega 1 -` fails because ordinals have no subtraction ([ordinals](ordinals.md)).
- `aleph1 continuum =` fails because ZFC can't decide it ([cardinals](cardinals.md)).
- Subverge isn't POSIX and won't be.

## Patches

Patches are welcome. Make sure the docs check prints `0 problems` and `make stress` passes ([testing](testing.md)), then open a pull request.
