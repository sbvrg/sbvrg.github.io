# Limits

The fixed sizes in Subverge. Going over one fails with an error, and [errors](errors.md) lists them.

| What | Limit |
|---|---|
| integers | up to 2^65536, bignums past 64 bits |
| data stack | 1024 values |
| `back` history | 64 lines |
| live locals | 256 |
| prompt line | 200 characters, minus the prompt |
| prompt history | 16 lines per tab |
| tabs | 4 |
| root units | 32 |
| unit name | 1 to 20 of `a-z 0-9 -` |
| `alloc` | 1 byte to 16 MiB |
| kernel heap | 64 MiB, or less if RAM is smaller |
| task stack | 256 KiB per tab |
| a slot | 1 MiB, root and each tab |
| timer | 100 Hz |
| screen | 80 by 25, 24 rows per tab plus the tab bar |
| help description | 52 characters |

