# Source layout

The source tree, file by file. [Internals](internals.md) describes how the parts fit together.

## boot/

| File | What it is |
|---|---|
| `boot.asm` | Multiboot header, page tables, long mode, the jump to `kmain` |
| `mbr.asm` | the boot sector on installed disks |
| `stage2.asm` | the second stage, which fakes Multiboot |

See [boot](boot.md).

## kernel/

| File | What it is |
|---|---|
| `main.c` | `kmain`, which starts everything in order |
| `cpu.c` | the IDT, the PICs, the PIT, the interrupt and fault handlers |
| `sched.c` | the four tab tasks and the [scheduler](scheduler.md) |
| `mem.c` | the heap |
| `vga.c` | text mode, the per-tab screens, the tab bar, the palette |
| `font.c` | the omega, aleph and subscript characters |
| `kbd.c` | the PS/2 keyboard |
| `disk.c` | ATA PIO |
| `persist.c` | `install`, `save`, the state header and the slots |
| `line.c` | the [prompt](prompt.md)'s line editor |
| `omega.c` | the language: parsing, values, lookup, transactions, the [GC](gc.md) |
| `words.c` | the core built-in words |
| `hw.c` | the machine words: memory, ports, PCI, screen, time |
| `big.c` | bignums, the integers past 64 bits ([numbers](numbers.md)) |
| `ord.c` | [ordinals](ordinals.md) and [cardinals](cardinals.md) |
| `root.c` | [root](root.md) units, rebuilding them, `open` and `unit` |
| `jit.c` | the [JIT](jit.md) |
| `dis.c` | the [disassembler](dis.md) |
| `help.c` | the [help](help.md) table and the docs check |
| `scrawl.c` | the [editor](scrawl.md) |
| `calc.c` | `calc`, the infix calculator |
| `sysinfo.c` | `sys-c` |
| `lib.c` | string and memory functions, `kprintf` |

## root/

The omega programs, one [unit](units.md) per file, run in file name order. [Root](root.md) lists their contents.

## test/

`host.c` and `qdrive.c`, and the `.qd` scripts. See [testing](testing.md).

## Where to start reading

Start with `kernel/main.c`, which brings everything up in order, then read `kernel/omega.c` outwards from `eval_line`, which contains the language itself.
