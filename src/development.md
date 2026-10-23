# Development

This page describes how Subverge is built, how the pieces of the source tree fit together, how the documentation is made and where each kind of change goes. It is meant for people who want to change Subverge. 

## Overview

The system has three layers, and a change goes in the lowest layer that can express it:

| Layer | Written in | Lives in | Needs a rebuild of the kernel |
|---|---|---|---|
| the kernel, ordinal | C and assembly | `kernel/`, `boot/` | yes |
| the shell, omega | C | `kernel/omega.c`, `kernel/words.c` and the other `*_words` tables | yes |
| the programs and utilities | omega | `root/` | no, but they are linked in at build time |

There is no filesystem, so there are no files to install. Everything the system needs is linked into one ELF image: the kernel, the root units, the help pages, the boot stages that `install` writes to a disk. A running system carries its own source for the programs in `root/`, since root is kept as omega source and rebuilt when it is edited ([root](root.md)).

## Requirements

| For | You need |
|---|---|
| the kernel | gcc, binutils (`ld`, `objcopy`), nasm, make |
| running it | `qemu-system-x86_64` |
| the ISO | `grub-mkrescue`, `xorriso`, the BIOS GRUB modules |
| the screenshots | `socat` and ImageMagick, for `test/` scripts that use the monitor socket |
| the website | `md2html` (md4c) and gawk |

On Exherbo, with the `virtualization` repository added:

    # cave resolve -x sys-devel/gcc sys-devel/binutils dev-lang/nasm app-virtualization/qemu \
        sys-boot/grub app-cdr/libisoburn

The kernel is compiled freestanding for x86-64. It does not link against libc, and the compiler must be able to produce 64-bit code with `-mgeneral-regs-only`, since the kernel never saves SSE state. Any gcc that accepts the flags in the Makefile works.

## Source

    $ git clone https://github.com/texivi/Subverge
    $ cd Subverge
    $ git clone https://github.com/sbvrg/sbvrg.github.io

The two repositories are independent. The website build finds the OS repository by path only for the screenshots and the page sync, so they can sit anywhere.

### The tree

| Directory | Holds |
|---|---|
| `boot/` | the Multiboot entry, the MBR and the second boot stage, all assembly |
| `kernel/` | the C source, one file per subsystem, and its headers |
| `root/` | the omega units, one per file, in the order they are built |
| `doc/` | the help pages, one markdown file per page |
| `test/` | the host harness, the QEMU driver and the `.qd` scripts |
| `build/` | everything the Makefile produces, thrown away by `make clean` |

The files in `kernel/` are listed under [The kernel files](#the-kernel-files).

## Building

    $ make                build/subverge.elf
    $ make run            boot it in QEMU
    $ make iso            build/subverge.iso
    $ make run-iso        boot the ISO in QEMU
    $ make disk           a blank 64M build/disk.img
    $ make run-install    the kernel with that disk attached, for install
    $ make run-disk       boot build/disk.img on its own
    $ make host           the interpreter as a Linux program
    $ make stress         the same, collecting garbage before every word
    $ make jit-test       boot QEMU and run the JIT test script
    $ make clean          throw build/ away

### The kernel image

`make` compiles every file in `kernel/` freestanding, with no standard library, no red zone, no SSE and no stack protector, and links the objects with `boot/boot.asm`, the root blob, the help page blob and the two boot stages into a 64-bit ELF, `build/ordinal.elf`. It is then converted to a 32-bit ELF with `objcopy`, since Multiboot loaders only accept 32-bit ELF, giving `build/subverge.elf`. The linker script is `linker.ld`, and it places the kernel at 1 MiB.

A new `.c` file in `kernel/` is picked up by the wildcard in the Makefile. A new header is not tracked individually: every object depends on every header, so a header change rebuilds everything.

### Blobs linked into the kernel

Three kinds of data are linked into the kernel with `ld -r -b binary`, which turns a file into an object with `_binary_<path>_start` and `_binary_<path>_end` symbols:

| Blob | Made from | Read by |
|---|---|---|
| `build/rootfs.bin` | every file in `root/`, concatenated in file name order | `kernel/root.c`, at boot |
| `build/docfs.bin` | every file in `doc/`, each preceded by a line `#>> name` | `kernel/doc.c`, when a page is opened |
| `build/bootbins.o` | the MBR and stage 2, assembled as flat binaries | `kernel/persist.c`, by `install` |

Unit files start with a number to set the order, so a unit can use the words of the units before it. The help pages are sorted by name, and the order doesn't matter, since the pager looks pages up by name.

### The ISO

`make iso` puts `build/subverge.elf` in an ISO tree with a generated `grub.cfg` that has one entry, which loads it with `multiboot` and boots it, and runs `grub-mkrescue` on the tree. The result is a live CD: it boots straight into the kernel and keeps nothing.

## Running

    $ qemu-system-x86_64 -cdrom build/subverge.iso -m 256M

`-m 256M` is the amount the system is tested with. See [QEMU](qemu.md) for the flags that matter: `-vga std` for graphics mode, `-audiodev` for `beep`, `-rtc base=localtime` for the clock, and the mouse, which QEMU gives to the guest after the first click in its window.

A direct `-kernel` boot, `qemu-system-x86_64 -kernel build/subverge.elf -m 256M`, is quicker than building the ISO and is what `make run` does. The two differ only in the loader: GRUB passes a memory map, and QEMU's own Multiboot loader passes less.

## Tests

    $ make host           the interpreter as a Linux program
    $ make stress         the same, collecting garbage before every word
    $ make jit-test       boot QEMU and run the JIT test script

`qdrive` types into a running QEMU and takes screenshots, see below. Run `make host`, `make stress`, the docs check and `make doccheck` before every commit.

### The docs check

    $ printf '@docs\n' | build/host

must print `0 problems`. It compares the table in `kernel/help.c` with the words that exist, and fails when a word has no entry, an entry has no word, a group is unknown, a description is longer than 52 characters or a stack effect is longer than 15. It checks the table that `help` reads and that the word pages in the help viewer are made from. The pages in `doc/` are checked by `make doccheck`.

## Adding a word

Built-in words live in the `*_words` tables at the bottom of their C files (see Built-ins below). Root words live in `root/` and are written in omega. Either way the word needs an entry in `kernel/help.c`, and the website needs a row in [all words](all-words.md).

### The help table

An entry in `kernel/help.c` has five fields:

    { "demos", "pair", "a b -- n", "Cantor pairing: two numbers into one number.", "3 4 pair" },

| Field | Meaning |
|---|---|
| group | one of the groups at the top of `help.c`; `help` lists a group's words together |
| name | the word, exactly as it is typed |
| effect | the stack effect, at most 15 characters, `--` between inputs and outputs |
| text | what it does, one sentence of at most 52 characters |
| example | a line that runs, or an empty string when there is nothing sensible to run |

The table is read by three things: `help` and `apropos` in the shell, the pages of words in the help viewer, and the docs check. A word with no entry is reported by the check, so the table can't fall behind the words.

### A root word

A root word goes in the unit it belongs with ([units](units.md)). Helpers that a program uses internally, and that nobody would type, are still words, so they need an entry too, in the `helpers` group.

### Checking it

    $ make host && printf '3 4 pair .\n@docs\n' | build/host
    $ make stress

## The website

The website is built from `src/` in the website repository. `src/*.md` are the pages, `src/template.html`, `src/home.html`, `src/header.html` and `src/footer.html` are the frame, `src/style.css` is the style, and `src/build.sh` turns them into the `.html` files at the root of the repository, which GitHub serves.

    $ bash src/build.sh
    built 99 pages

`md2html` converts each page, a `gawk` filter gives every heading an `id`, and a second filter builds the contents list that is shown at the top of every page with four or more headings. The root `.html` files are build output and are committed, since GitHub Pages serves the repository as it is. Edit `src/`, never the `.html` files.

### Pages on both sides

Most pages exist in both repositories, with different content: the website version has screenshots, links between pages as `.md` links, and the installation and hardware guides, while the version in `doc/` has no images and links that work in the pager. When a fact changes, change both. When a page is copied from `doc/` to the website, a link to a page the website doesn't have becomes plain text, `?word` links become code, and `>line` links become text.

### Screenshots

Screenshots are taken from QEMU with its monitor, at the default text size, and are saved in `images/` with a number in front, in the order they were added. Take them on a clean boot of the live ISO so that they show what a user sees.

## How the kernel starts

1. GRUB on the ISO, or the [bootloader](boot.md) of an installed disk, loads the kernel at 1 MiB and jumps to it in 32-bit protected mode.
2. `boot/boot.asm` identity-maps the first 4 GiB with 2 MiB pages, turns on long mode and calls `kmain`.
3. `kmain` copies `.data` aside so that `install` can write a clean kernel, then brings up VGA, the CPU tables and the PICs, and reads the Multiboot information.
4. The heap is set up after the kernel, up to 64 MiB. Then the scheduler and persistence, which reads the state header of an installed drive.
5. Every built-in is registered, and root is built from the units linked into the kernel, or from slot 0 of the disk when it exists and builds.
6. Four tasks start, one per tab. The PIT is set to 100 Hz, the keyboard is enabled and interrupts are turned on. `kmain` becomes the idle task.

Each tab then loads its saved world, tab 1 runs `startup`, and all four wait at a prompt.

## The kernel files

| File | Holds | Page |
|---|---|---|
| `main.c` | `kmain`, the start order above | |
| `cpu.c` | IDT, PICs, PIT, interrupt and fault handlers | [interrupts](interrupts.md) |
| `sched.c` | the four tab tasks and the scheduler | [scheduler](scheduler.md) |
| `mem.c` | the heap, one first-fit allocator | [memory](memory.md) |
| `vga.c`, `font.c` | text mode, a screen buffer per tab, tab bar, palette, graphics mode, the pointer | [screen](screen.md) |
| `kbd.c`, `mouse.c` | PS/2 keyboard and mouse, one key queue per task | [keyboard](keyboard.md), [mouse](mouse.md) |
| `disk.c`, `persist.c` | ATA PIO, the state header and the slots | [disk layout](disk-layout.md), [saving](saving.md) |
| `omega.c`, `words.c` | the language and the core words | [language](language.md) |
| `hw.c` | the machine words: memory, ports, PCI, screen, time | [machine](machine.md) |
| `big.c`, `ord.c` | bignums, ordinals, cardinals | [numbers](numbers.md), [ordinals](ordinals.md) |
| `root.c` | root units, rebuilding, `open` and `unit` | [root](root.md) |
| `jit.c`, `dis.c` | the JIT and the disassembler | [jit](jit.md), [dis](dis.md) |
| `help.c`, `doc.c` | the help table, the docs check, the page viewer | [help](help.md) |
| `scrawl.c` | the editor | [scrawl](scrawl.md) |
| `line.c`, `calc.c`, `sysinfo.c`, `lib.c` | the line editor, `calc`, `sys-c`, string functions and `kprintf` | |

To read the code, start with `kernel/main.c` and then follow `eval_line` in `kernel/omega.c`, which contains the language.

Everything runs in ring 0 in one address space. A fault in a tab restarts that tab and leaves the others running. A fault in the kernel itself panics. Shared state such as the heap, the screen buffers and the devices is touched with interrupts off (`irq_save` and `irq_restore`), and interrupt handlers never allocate or yield.

## Checklist for kernel changes

1. Run `make host` and feed the affected words through `build/host`. Run `printf '@docs\n' | build/host` and expect `0 problems`. Remember that `kernel/cpu.c`, `kbd.c`, `disk.c`, `persist.c`, `font.c`, `main.c` and the assembly are not part of the host build (`HOSTSRC` in the `Makefile`), so a change in them gets no coverage from this step.
2. Run `make stress` for any change to the allocator, the shell, the garbage collector, a new built-in, or anything that holds a pointer across an allocation. A freed block is filled with `0xDD`, so a dangling use shows up as that pattern.
3. Build the real kernel with `make` and check that it still links with `-Wall -Wextra` clean. The flags forbid SSE (`-mgeneral-regs-only`) and the red zone (`-mno-red-zone`). Do not add floating point, `memcpy` variants that use vector registers, or code that assumes a red zone.
4. Boot with `make run` (`qemu -kernel build/subverge.elf -m 256M`). Check that all four tabs start, that F1 to F4 and Alt+1 to 4 switch, and that the tab bar clock advances.
5. Boot the ISO with `make run-iso`. A change to `boot/boot.asm`, to `linker.ld` or to the Multiboot header is visible here and in step 4 but a mistake in the header can pass one and fail the other. Check that `sys` shows the expected memory size.
6. If the change touches boot, `persist.c`, `disk.c`, the linker script or the size of `.data`, run `make run-install`, install to the drive, then boot it with `make run-disk`. Verify that the saved definitions, theme and logo return in the right tabs. The image must stay within `0x90000` bytes.
7. Run the scripted tests that apply. `make jit-test` boots the kernel under `build/qdrive` and drives it with `test/jit.qd`. The scripts in `test/*.qd` (`boot.qd`, `iso.qd`, `install.qd`, `isoinst.qd`, `gfx.qd`, `startup.qd`, `win.qd`, `help.qd`) cover the boot paths, graphics mode, installation and the pager.
8. For every function you add that runs in an interrupt handler, confirm it does not call `kmalloc`, `kfree`, `yield`, or anything that blocks, and that it touches shared state only through `volatile` single-writer rings or inside `irq_save`.
9. For every function that touches state shared between tasks, between a task and an IRQ, or the screen, confirm which side writes and whether an `irq_save` / `irq_restore` pair is needed. Keep the sections short: tick accounting stops while interrupts are off, and `disk_rw` already keeps them off for up to 128 sectors.
10. Use `irq_restore(flags)` with the value returned by `irq_save`, never an unconditional `sti`. Callers can already be inside an interrupt-off section.
11. Anything stored per tab belongs in `struct task` or `struct term`. Check what `task_fault` does to it: the key ring, `brkflag`, `mouse_on` and the shell state `om` survive a restart, `wait_key` and `wake_at` do not. A new field that must be reset on restart has to be reset in `task_fault`.
12. Output code must go through `vga_put` or `kputc` so it lands in the calling tab's buffer. Use `hw_put` only for the tab bar, panic and pointer, which are not part of any tab. Test with output from a background tab and confirm the `*` marker appears and the buffer is replayed by `switch_tab`.
13. Any change that writes hardware cells while the pointer may sit on them must keep the swap in step: either go through `vga_put`, or restore the cell before writing and call `mouse_redraw` after. Test with the pointer over the changed area, including row 0.
14. Test in both text and graphics mode. In graphics mode (`gfx` in QEMU started with `-vga std`) `hw_put` does nothing and `vga_put` updates buffers only, so code that must be visible in both modes needs a branch on `gfx_on`. Switch tabs while in graphics mode and check that `gfx_leave` restores the font (the omega and aleph glyphs) and the theme colours.
15. For a change to `on_key`, the tables or the modifier handling, test in QEMU: Shift, Caps, Ctrl-C during a loop, Shift-Tab, the arrow keys, and the keypad Enter. The host harness does not run `on_key`.
16. For a change to `mouse.c` or the pointer code, test in QEMU with a graphical window, with and without a wheel, in the pager and on the tab bar.
17. Run the change with a small `-m` value and a large one. The heap is the smaller of the RAM above `_kernel_end` and 64 MiB, and each tab takes 256 KiB of stack plus the world, so small configurations run out of memory first and end in `ran out of memory`.
18. Do not change `NTABS`, `VW`, `VH`, `SLOT_SECTORS`, `LBA_*` or the `struct state_header` layout without updating every user: the tab bar layout, `tab_at`, the slot count, the `_Static_assert` on the header size, `install-to`, and the stage2 header offsets in `boot/stage2.asm`. A disk written with one layout is read with another by `persist_init` without any version check beyond the `SVSTATE1` magic.

## The interpreter

Every value is a 24-byte cell `V` (`kernel/omega.h`): a tag and either a number or a pointer to an object. Quotes, strings, bignums, worlds and the like are objects on the tab's collected heap. Names are interned strings, and a built-in is the function stored on its name.

`eval_line` runs one line of input as a transaction. It works on a copy of the stack and the dictionary and stores the result as the new world, and keeps the old one for `back`, only when the line raised no error. A failed line changes nothing. Effects outside the world, such as ports, `poke` and drawing, are not undone ([transactions](transactions.md)).

A quote that has run twice is compiled to x86-64 by `kernel/jit.c`, and `define` and a root rebuild bump `jit_version` so that stale code is recompiled ([jit](jit.md)).

## The garbage collector

### Roots and reachability

The collector is a stop-the-world mark and sweep over the objects in `W->objs` of the current tab. Each tab collects its own objects. `gc()` marks from these roots:

| Root | Why |
|------|-----|
| `W->cur`, every entry of `hist` and `fut` | Committed worlds (stack quote and dictionary). |
| `W->stk[0 .. sp-1]` | The live data stack. Cells above `sp` are not roots. |
| `W->loc[0 .. nloc-1]` | Live locals. |
| `W->keep[0 .. min(nkeep,256)-1]` | Values held by built-ins. |
| `W->dict` | The working dictionary of the line. |
| `W->linequote` | The quote being run. |

Pinned objects are skipped by `mark`: `mark` returns at once for an object whose `pinned` field is set, and does not look at its children. The objects reachable from `root_dict` are pinned because `rebuild` in `kernel/root.c` creates them with `W->pin = 1`. The same holds for the interned strings and for the two ordinal atoms made in `ord_init`. A pinned object may therefore only point to other pinned objects.

`mark` is iterative along `bind.next` chains and recursive through quote items and ordinal exponents.

### Safe points

A collection runs only inside `gc_point`, and `gc_point` is called from three places: the top of every iteration of the `run` loop, `h_tick` in compiled loops, and `omega_main`, which calls `gc()` directly before every prompt. `gc_point` does nothing while `W->pin` is set or while `nkeep` is above 256. Otherwise it collects when `W->nobjs > W->gc_threshold`. After a collection `gc_threshold` is `max(8192, 2 * nobjs)`. Its initial value is 0, so the first safe point of a new tab collects.

### Mark and sweep order

1. Mark from the roots listed above.
2. Walk `W->objs`. A marked object has its mark cleared and stays. An unmarked object is unlinked. If it is a quote, `jit_forget` releases its machine code. Then `kfree` frees it and `nobjs` is decremented.
3. Increment `ngc` and set the new threshold.

### GC_STRESS

`make stress` builds `build/stress` with `-DGC_STRESS`. In this build `gc_point` collects at every call regardless of the threshold, and `kfree` in `kernel/mem.c` overwrites each freed block with the byte 0xDD. A built-in that keeps a pointer to a freed object then reads 0xDD bytes, which show up as crashes or visibly wrong values. Run every new built-in that calls back into omega code through `build/stress`. Compiled loops reach `gc_point` through `h_tick`, so the stress build exercises compiled code only inside loops.

    printf '1 2 3 3 list [ dup * ] map .\n' | build/stress

### Rules for built-ins

A collection cannot happen while a built-in runs unless the built-in calls into omega code. The calls that reach a safe point are `call`, `run`, `exec_word`, `exec_item` and `eval_line`. This gives these rules:

1. A built-in that never calls back can hold raw pointers to any value freely, including newly allocated ones. It needs no `keep`.
2. A built-in that calls back must `keep(v)` every value that it will use after the call and that is no longer on the stack. A value it popped is not a root. `unkeep(n)` removes the last `n` entries and must run on every path, including after an error.
3. `call(v)` keeps `v` itself while it runs. The quote argument of `times`, `for`, `while`, `each`, `map` and `filter` is kept by the built-in for the whole loop, because it is called again on each iteration.
4. A result is safe once it has been pushed. Build it before the call that needs it only if it is kept.
5. A built-in must not store a `V` in a C static or in malloc'd memory unless the object is pinned. The root units keep `str *` names of interned strings, which are pinned.
6. `keep` stores into a 256-entry array and counts beyond it without storing. The collector refuses to run while the count is above 256, so deep recursion through built-ins that keep values degrades to no collection and does not corrupt anything.
7. Do not read `W->stk` above `sp`, and treat pointers into it as invalid after any call back, since a nested call can move `sp` and overwrite those cells.

## Built-ins

### Table type and registration

    struct builtin { const char *name; void (*fn)(void); };

Each module ends with a `const struct builtin` array terminated by `{ NULL, NULL }`.

| Table | File | Contents |
|-------|------|----------|
| `core_words` | `kernel/words.c` | Stack, arithmetic, logic, flow, lists, text, output, names, `back`, `redo`, `eval`, `try`, `fail`, `trace`, `edit`, `calc`. |
| `hw_words` | `kernel/hw.c` | Memory and ports, cpu, pci, memory map, clocks, the screen, keys, themes, logos, `reboot`, `halt`. |
| `ord_words` | `kernel/ord.c` | `omega`, `epsilon0`, `omega1`, `aleph0`, `aleph1`, `aleph`, `continuum`, `card`, `ordinal?`. |
| `root_words` | `kernel/root.c` | `root`, `open`, `unit`, `src`. |
| `persist_words` | `kernel/persist.c` | `drives`, `home`, `ask`, `install-to`, `save`. |
| `jit_words` | `kernel/jit.c` | `jit`, `jit-on`, `jit-off`, `compile`, `addr`. |
| `dis_words` | `kernel/dis.c` | `dis`, `disr`. |
| `help_words` | `kernel/help.c` | `help`, `apropos`. |
| `doc_words` | `kernel/doc.c` | `doc`, `docs`. |
| `mouse_words` | `kernel/mouse.c` | `mouse`, `mouse?`. |

The tables are declared `extern` in `kernel/omega.h` and registered by `kmain` in this order: core, hw, ord, root, persist, jit, dis, help, doc, mouse. `test/host.c` registers the same tables with its own `persist_words` stub. A new module needs an `extern` declaration, a `register_words` call in both places, an entry in `HOSTSRC` in the `Makefile` if it should be part of the host build, and an entry in the `sets[]` array of `help_check`.

Words written in omega itself live in `root/*.om` (see Root units below).

### Helpers

| Function | Behaviour |
|----------|-----------|
| `need(n, "w")` | Returns 1 if the stack has at least `n` values. Otherwise fails with `w needs more values on the stack` and returns 0. |
| `pop()` | Removes and returns the top cell. It does not check; call `need` first. |
| `push(v)` | Does nothing if an error is pending. Fails on `T_NONE` (`that value can't go on the stack`) and on a full stack. |
| `want(v, t, "w")` | Returns 1 if `v.t == t`. Otherwise fails with `w needs a number`, `a string`, `a quote` or `a 'name`. |
| `pop_int("w", &n)` | `need`, pop, and `want(T_INT)`. A bignum fails with `w needs a number that fits in 64 bits`. |
| `pop_str("w", &s)` | `need`, pop, and `want(T_STR)`. |
| `brk()` | Tests and clears the Ctrl-C flag and fails with `interrupted`. Long loops in built-ins call it on each iteration. |
| `fail(fmt, a)` | Records the first error. `fmt` takes exactly one `%s`, filled from `a`. |
| `keep(v)`, `unkeep(n)` | Collector roots for the duration of a call back. |

Arguments are popped from the top, so the last argument comes first. `b_poke` in `kernel/hw.c` is written `pop_int("poke", &a) && pop_int("poke", &v)` and so reads the stack picture `v a --`. Chaining the calls with `&&` or `||` stops at the first failure.

### Error message conventions

Messages are one lowercase sentence without a final period. They name the word that failed at the start (`peek needs a number`) or state the problem in plain terms (`division by zero`, `that range is too big`, `NAME isn't defined`). Because `fail` formats with a single `%s`, a message without an argument is written with a trailing `%s` and an empty string:

    fail("pick needs 0 or more%s", "");

A message that has to carry a value passes it as the argument: `fail("%s isn't defined", s->s)`. A message with several parts is formatted into a local buffer first and passed through `fail("%s", m)`, as `want` and `pop_int` do. The message buffer holds 95 characters. A word that can fail for several reasons gives each its own message. The messages are visible to users, so the same phrases appear in [errors](errors.md).

### Allocation in built-ins

`gnew` and `quote_new` can return NULL. A built-in that writes into the object must test for NULL first, as `append` does with `quote_new`. A built-in that only pushes the result may leave the test out; the error is already recorded and the push is a no-op.

`kmalloc_try` for temporary buffers must be paired with `kfree` on every path. `join` and `str` show the pattern: allocate, build, push a new `str` copy, free. Do not leave `kmalloc`'d memory reachable only from a C local across a call back.

### A worked example

The word `clamp` takes `n lo hi` and leaves `n` limited to the range. It belongs to the `math` group.

Add the function above `b_bnot` in `kernel/words.c`:

    static void b_clamp(void) {
        i64 n, lo, hi;
        if (!pop_int("clamp", &hi) || !pop_int("clamp", &lo) || !pop_int("clamp", &n)) return;
        if (lo > hi) { fail("clamp needs the low end first%s", ""); return; }
        push(I(n < lo ? lo : n > hi ? hi : n));
    }

Add it to `core_words`:

    { "clamp", b_clamp }, { "neg", b_neg },

Add the help entry to `docs[]` in `kernel/help.c`, in the `math` block:

    { "math", "clamp", "n lo hi -- m", "Limits n to the range lo to hi.", "15 0 10 clamp   gives 10" },

Build the host harness and try it:

    make host
    printf '15 0 10 clamp\n-3 0 10 clamp\n5 10 0 clamp\n@docs\n' | build/host

The harness prints the stack after each line. The expected results are `10`, then `10 0`, then an error line for the third input that leaves the stack at `10 0`, and finally `0 problems` from `@docs`. The failed line shows the transaction at work: `5` was popped before the error, but the committed stack is unchanged.

The remaining steps:

1. If the word is a good place for a link, mention it on a page in `doc/*.md`. Run `make doccheck` to confirm the links resolve.
2. A line in a help page that consists only of known words becomes a link that runs it, so an example that uses the new word gets its link without any markup.
3. Run `make stress` and feed the same lines to `build/stress` if the word calls back into omega code.

### The docs check

`help_check` in `kernel/help.c` is compiled only in the host build. `test/host.c` calls it for the input line `@docs` and prints the number of problems. It reports:

| Message | Cause |
|---------|-------|
| `undocumented builtin: NAME` | A registered built-in without a `docs[]` entry. |
| `undocumented root word: NAME` | A non-tombstone binding in `root_dict` without an entry. |
| `doc for a word that doesn't exist: NAME` | An entry (outside group `syntax`) naming something that is neither a built-in nor a root word. |
| `bad group on NAME` | The group is not in `groups[]`. |
| `text too long: NAME` | `text` longer than 52 characters. |
| `effect too long: NAME` | `effect` longer than 15 characters. |

Run `@docs` after every change that adds, renames or removes a word. The output must be `0 problems`.

### What the host harness cannot run

`build/host` links the real omega, bignum, ordinal, root, line, help, doc and JIT code with a stub kernel. Words that touch hardware dereference raw addresses or execute privileged instructions. `peek`, `time` and similar words terminate the harness with a core dump. Test them under QEMU. `ticks` returns a counter that advances only when the harness yields.

## Checklist for interpreter changes

1. Read the fields of `V`, `quote` and `struct omega` that the change touches, and check `kernel/jit.c` for a hard-coded layout: `VSZ`, `copy_v`, `push_int_rax`, the `imul r12,r14,24` bytes in `sync_in`, and every `offsetof(struct omega, ...)`.
2. A new tag needs entries in `want`'s table if it can appear in an error, in `type`'s `names[]` array, in `repr`, in `ord_source`/`srcmode` handling if it must survive saving, in the `lit` cases of `compile_seq`, and in `markv` if it carries a pointer.
3. A new object kind needs a branch in `mark` for its children and a size computation in its constructor. Allocate it with `gnew` and test the result for NULL.
4. Every built-in must call `need` or a `pop_*` helper before `pop`, report errors with `fail` and return, and leave the stack in a usable state. A line that fails is discarded, so a partial effect on the stack is not a correctness problem, but a partial effect outside the stack is.
5. A built-in that calls `call`, `run`, `exec_word` or `eval_line` must `keep` every value it still needs and `unkeep` on every path. Check it with `make stress`.
6. State that is not on the stack or in the dictionary is not rolled back by a failed line or by `back`. Keep new state either in the stack and dictionary, or document that it is outside the transaction.
7. A new built-in needs an entry in a `const struct builtin` table, an entry in `docs[]` in `kernel/help.c` within the 52 and 15 character limits, and a clean `@docs` run. A new module table also needs the `extern` declaration, `register_words` calls in `kernel/main.c` and `test/host.c`, an entry in `HOSTSRC`, and an entry in `sets[]` of `help_check`.
8. A change to the meaning of an existing built-in name needs a check of the compiler: if `inline_word` or the control forms in `compile_seq` handle that name, update the fast path, or the slow path will disagree with it. Compare results with `jit-off` and `jit-on`.
9. A change that makes `define` or `rebuild` replace words must keep the `jit_version` bump, otherwise compiled quotes keep calling the old behaviour.
10. A change to the parser needs a matching change in `repr` and in `omega_source`, because saved worlds are text that goes back through `parse`. Run `@roundtrip` in the host harness and check that it prints `MATCHES`.
11. A change to `eval_line` has to keep three properties: a failed line commits nothing, `back` and `redo` discard the rest of the line, and a line that changes nothing adds no history entry. Test each with a short input in `build/host`.
12. Limits that appear in messages (`DEPTH`, `STK`, `NLOC`, `HIST`, 256 items, 32 nesting levels, `MAXL`) also appear in pages under `doc/` and in the site pages. Update them together ([limits](limits.md)).
13. The kernel is built with `-mgeneral-regs-only`: C code in the kernel cannot use floating point or vector registers. The host build has no such restriction, so a change that compiles in `build/host` can still fail in `make`.
14. Run, in order: `make host` and a set of inputs through `build/host`, `make stress` with the same inputs, `make doccheck`, `make` for the kernel, and a QEMU session (`make run`, or `make jit-test`) for any change that involves hardware words, the compiler, the keyboard or the screen.
15. Words that touch hardware (`peek`, `time`, ports, the screen words) crash the host harness. Their tests belong in QEMU.

## Root units

Root is the part of the system written in omega. It holds every utility, game and demo that is not a C builtin, and the strings the help system and the tour are made from. The source is the files `root/*.om`. A running system holds root as a list of units, each with its source text and the names it defines, and as one dictionary (`root_dict`, declared in `kernel/omega.h`) that every tab searches after its own definitions. The code is `kernel/root.c`. The user-facing description is in [root](root.md) and [units](units.md). This section describes what the code does.

### From files to a blob

`build/rootfs.bin` is made by one rule in the Makefile:

    build/rootfs.bin: $(sort $(wildcard root/*.om)) | build
        cat $^ > $@

`build/rootfs.o` is `ld -r -b binary` of that file. The linker provides the symbols `_binary_build_rootfs_bin_start` and `_binary_build_rootfs_bin_end`, which `kernel/root.c` declares as `extern const char[]`. The host harness (`make host`) links the same `build/rootfs.o`.

Consequences of the rule:

- The files are concatenated in the order of `sort`, which is the byte order of the file names. The numeric prefixes (`00-`, `05-`, `10-`, up to `80-`) exist to fix this order. A new file is picked up without a change to the Makefile, and it must have a prefix that puts it where it belongs.
- `cat` adds nothing between the files. Every file must end with a newline, or the first line of the next file (its `#>>` header) is joined to the last line of the previous unit and the header is not recognised.
- The file name has no meaning to the kernel. The unit name comes from the header line inside the file.
- The blob is read-only data in the kernel image. A running system copies each unit into the kernel heap (`kmalloc`) when it splits the blob.

### Unit header lines

A unit starts at a line that begins with `#>> ` (hash, two greater-than signs, one space) and has at least one character after it. `split_units()` in `kernel/root.c` tests `eol - p > 4` and the four bytes `#>> `. The rest of the line is the unit name. The text after that line, up to the next header or the end of the blob, is the unit source.

| Property | Value | Where |
|---|---|---|
| Header prefix | `#>> ` at the start of a line | `split_units()` |
| Name length stored | at most 23 bytes (`char name[24]`) | `struct unit` |
| Name length accepted by `unit` | 1 to 20 characters | `b_unit()` |
| Characters accepted by `unit` | `a` to `z`, `0` to `9` and `-` | `b_unit()` |
| Units in root | at most `NUNITS`, which is 32 | `kernel/root.c` |
| Names recorded per unit | at most `UWORDS`, which is 96 | `kernel/root.c` |

Text before the first header is dropped. A header line inside a unit that is not at the start of a line is ordinary text. When the blob has more than `NUNITS` headers the rest of it is ignored.

The units that ship with the system, in build order:

| File | Unit name |
|---|---|
| `00-core.om` | `core` |
| `05-apps.om` | `apps` |
| `10-sys.om` | `sys` |
| `20-top.om` | `top` |
| `30-inspect.om` | `inspect` |
| `40-infinity.om` | `infinity` |
| `50-fun.om` | `fun` |
| `55-mandel.om` | `mandel` |
| `56-toys.om` | `toys` |
| `57-tools.om` | `tools` |
| `60-install.om` | `install` |
| `70-dev.om` | `dev` |
| `80-learn.om` | `learn` |

The prefix of the file and the name of the unit are independent. Nothing checks that they agree.

### How root is built at boot

`root_boot()` is called once, from the kernel start-up path and from `test/host.c`, after the builtin tables are registered. It does the following:

1. Calls `persist_load(0, &len)`. Slot 0 of the state area of an installed drive holds the text of root as the user last left it. On the live ISO and in `build/host` there is no home drive, `persist_load` returns `NULL`, and the next step is skipped.
2. If a saved root exists, `split_units()` splits it and `rebuild(-1, NULL)` builds it. When that succeeds, `root_boot()` returns. The built-in blob is not consulted.
3. If the saved root does not build, `boot_err` is set to `the saved root didn't build, using the built-in one` and the blob linked into the kernel is split and built instead.
4. If the built-in blob does not build either, `boot_err` holds the error, formatted as `unit: message`.

`root_boot_error()` returns `boot_err` or `NULL`. Tab 1 reads it in `omega_main()` (`kernel/omega.c`): without an error it evaluates `'startup defined? [ startup ] [ sys ] if`, and with an error it calls `sysinfo()` and prints `! root: <message>` in light red. `test/host.c` prints `ROOT ERROR: <message>` after `root_boot()`. A root that fails to build in the harness therefore shows up at once.

`rebuild(which, src)` is the only function that builds root. `which` is the index of the unit whose source is replaced by `src`, or `-1` for no replacement. The steps:

1. The caller's interpreter state is saved: the operand stack (`W->stk`, `W->sp`), `W->nloc`, `W->depth`, `W->tracing` and the dictionary `W->dict`.
2. `W->pin` is set to 1. Objects allocated while it is set are pinned and are never collected, which is how root words and their literals stay alive.
3. `start` is chosen. For `which` of 0 or `-1` it is 0 and the build begins from an empty dictionary. For a larger `which` that is not past `nafter` it is `which`, and the dictionary starts as `after[start - 1]`, the dictionary as it was at the end of the previous unit. The units before `start` are not run again.
4. For each unit from `start` to the last, the interpreter state is cleared (`W->err`, `W->sp`, `W->nloc`, `W->depth`, `W->tracing` set to 0), the source is parsed with `parse_text()` (the replacement text for unit `which`, otherwise `units[i].src`) and the resulting quote is run with `run()`. A unit is a program. Each `[ ... ] :name` in it runs at build time and binds the name.
5. If `W->err` is set after a unit, the error is formatted as `<unit>: <W->errmsg>` into a static 120-byte buffer and the loop stops.
6. After each unit the dictionary head is stored in `marks[i]`, and the names bound by that unit (the bindings between the previous head and the new one, without duplicates, at most `UWORDS`) are stored in `words[i]`.
7. The saved interpreter state is restored and `W->pin` is cleared, on success and on failure alike.
8. On failure the function returns the message and changes nothing else. `root_dict`, `units[]` and `after[]` keep their old values.
9. On success `root_dict` is set to the new head. For every binding of the old chain down to the shared tail, `jit_release_one()` is called. Then `jit_sweep()` runs and `jit_version` is incremented, so compiled quotes in all tabs are discarded and compile again when they next run twice (see [jit](jit.md)).
10. The shadow note is rebuilt (see below), `units[i].nwords` and `units[i].words` are updated for the rebuilt units, `after[i]` is set, and `nafter` becomes `nunits`.

Old root objects are not freed. A tab that copied a quote out of the old root with `get` keeps a valid object.

### The words `root`, `open`, `unit` and `src`

`root_words[]` in `kernel/root.c` registers four builtins.

| Word | Effect | Behaviour |
|---|---|---|
| `root` | `--` | Lists the units: name padded to 10, size in bytes, `(draft)` if an unsaved edit is held, then the names the unit defines. The names are printed oldest first and the list is cut after two lines with `..`. The line ends with `Edit a unit with 'word open, where word is any name in it.` |
| `open` | `'name --` | Opens the unit in the editor `scrawl` with the title `root/<unit>` |
| `unit` | `s --` | Creates an empty unit named `s` at the end of root and opens it |
| `src` | `'name -- s` | Pushes the source text of the unit that contains `name` |

`open` and `src` find the unit with `find_unit()`. It compares the symbol with unit names first and then with the names recorded for each unit. A symbol that is both a unit name and a word in another unit selects the unit with that name. The error for an unknown symbol is `<name> isn't in any root unit`.

`unit` checks the name in this order: length 1 to 20 (`a unit name is 1 to 20 characters`), characters (`a unit name uses lowercase letters, digits and -`), duplicates (`<name> is already a unit`), and room (`there is no room for another unit` at 32 units). The new unit is created with the source `"\n"` and is added to root before the editor opens. If the user leaves the editor without a successful build, the empty unit stays in root.

### Editing and rebuilding

`edit_unit(i)` is the common path of `open` and `unit`.

1. The text to edit is the draft if the unit has one, otherwise the source.
2. `scrawl("root/<name>", text, strlen, &outlen)` returns the edited text in a heap buffer, or `NULL` when the editor was left without saving. A `NULL` ends the command.
3. `rebuild(i, out)` is called with the edited text.
4. If it fails, the old draft is freed and the edited text becomes the draft. The command fails with `root unchanged, <error> (your edit is kept: open it again)`. Root, `units[i].src` and the saved copy on the drive are unchanged.
5. If it succeeds, the old source and draft are freed, the unit takes the new text and length, the draft is cleared, `persist_save_root()` writes root to the drive if the system is installed, and `edited root` is printed in light green. When `shadow_note` is not empty it is printed in peach on the next line.

A draft is part of the running system only. It is not written to the drive and is lost at reboot.

### Persistence in an installed system

`persist_save_root()` (`kernel/persist.c`) returns at once when `home < 0`, the live case. Otherwise it calls `root_source()`, which writes every unit as `#>> <name>`, a newline, the source, and a closing newline if the source did not end with one, and stores the result in slot 0. The buffer is `SLOT_SECTORS * 512 - 512` bytes, which is 1048064 bytes with `SLOT_SECTORS` at 2048. `root_source()` returns 0 when the text does not fit, and `persist_save_root()` then writes nothing.

Root is saved:

- after each successful edit or `unit` (`edit_unit()`);
- by `install-to`, after the home drive is set;
- by `save`.

The state area has `NSLOTS = 1 + NTABS` slots, which is 5 (`kernel/persist.c`): slot 0 for root and slots 1 to 4 for the four tabs. The header sector holds a checksum for each slot. `persist_load()` refuses a slot whose length is larger than `SLOT_SECTORS * 512 - 1` or whose checksum does not match, and returns `NULL`.

The saved text is the whole of root. Once a drive holds a root, changes to `root/*.om` in a later build do not reach that drive, because step 2 of `root_boot()` uses the saved text. To see a changed root in QEMU, boot the ISO or `-kernel build/subverge.elf` without an installed drive, or use `build/host`. The layout of the state area is in [disk-layout](disk-layout.md), and [saving](saving.md) describes what the user sees.

## Writing a program

A program is a root word that takes the screen, loops until a quit key, and gives the screen back. This section builds one: a dot that moves with the arrow keys and jumps to the mouse pointer on a click. It is registered in `apps`, documented in `help.c`, and checked in `build/host` and in QEMU.

### The program

Create `root/58-wander.om`. The prefix puts it after `57-tools`, and every word it uses is defined in `00-core.om` or is a builtin.

    #>> wander
    # moving dot

    [ { x y } 32 x y 0 put ] :dot-off

    [ "wander" title wipe nocursor
      40 { x } 12 { y } 1 { going }
      "  Arrows move, a click moves to the mouse, q leaves." 2 23 8 text
      [ going ] [
        key? { k }
        k quit-key? [ 0 ->going ] when
        x y dot-off
        k 256 = [ y 1 - 1 max ->y ] when
        k 257 = [ y 1 + 22 min ->y ] when
        k 258 = [ x 1 - 0 max ->x ] when
        k 259 = [ x 1 + 79 min ->x ] when
        mouse? [ mouse { mx my b } b 1 & 1 = [ mx ->x my 1 max 22 min ->y ] when ] when
        219 x y 14 put
        2 sleep
      ] while
      wipe "omega" title
    ] :wander

The parts:

- `"wander" title` sets the tab label. `wipe` clears the tab screen and `nocursor` hides the cursor.
- `40 { x } 12 { y } 1 { going }` pushes three values and binds them as locals in order, so `x` is 40, `y` is 12 and `going` is 1. The result is the same as `40 12 1 { x y going }`.
- The hint is drawn once, at row 23, with `text`: string, x, y, colour.
- `key? { k }` reads a key code or `-1`. `k quit-key?` is true for `q`, Esc and Ctrl-C and clears `going`.
- `x y dot-off` blanks the old position before it changes. `dot-off` is `32 x y 0 put`: character 32, colour 0.
- The arrow codes are 256 (up) to 259 (right). `max` and `min` keep the dot inside rows 1 to 22 and columns 0 to 79. Row 0 of the tab screen is the first row under the top bar of the system, so the area is rows 0 to 23 and the programs keep the last row for the hint.
- `mouse?` pushes 1 when a PS/2 mouse was found at boot. `mouse` pushes the pointer column, the pointer row and the button bits (bit 0 is the left button, bit 1 the right). In the code the row has already been reduced by one, because the top bar is row 0 of the physical screen (`b_mouse()` pushes `mouse_cy - 1`). The `1 & 1 =` test selects the left button.
- `219 x y 14 put` draws a full block in colour 14.
- `2 sleep` waits 20 ms. A `sleep` also checks the break flag, so Ctrl-C works even in a loop that never calls `key?`.
- `wipe "omega" title` returns the screen and the label.

The loop reads the mouse state directly with `mouse` and does not use events. Events are only queued while the pager is open (`mouse_on` in the task structure); a program that wants clicks polls the button bits each pass, as `scribble` does.

### Registering it in apps

Add one line inside the list in `root/05-apps.om`:

    [ "wander" "Move a dot." ]

Keep the description to 25 characters or fewer. `apps` reads `app-list` on every call, so the entry is live as soon as root builds. The same edit can be made inside a running system with `'apps open`.

### The help entry

`kernel/help.c` has one table, `docs[]`, and every root word needs a row in it. The row is `{ group, name, effect, text, example }`. For the program:

    { "games", "wander", "--", "Arrows or the mouse move a dot. q leaves.", "wander" },
    { "helpers", "dot-off", "x y --", "Clears one cell.", "40 12 dot-off" },

The rules that `help_check()` enforces:

| Rule | Limit |
|---|---|
| `group` is one of the entries of `groups[]` | `syntax`, `stack`, `math`, `logic`, `flow`, `lists`, `text`, `io`, `names`, `world`, `infinity`, `memory`, `ports`, `time`, `screen`, `machine`, `dev`, `tools`, `demos`, `games`, `util`, `helpers` |
| `text` is at most | 52 characters |
| `effect` is at most | 15 characters |
| every builtin and every root word has a row | the check reports `undocumented builtin` and `undocumented root word` |
| a row names a word that exists | otherwise `doc for a word that doesn't exist` |

Place the row in the part of the table where the group is, because the group page prints the rows in table order. Helper words go in the group `helpers`, which is left out of the overview. A game goes in `games`, a demo of mathematics in `demos`, and an everyday program in `tools`. The `example` string is shown on the word page as `Try:` and it is the line that the pager offers to run. Leave it empty when the word needs arguments that cannot be shown in one line.

### Verifying in build/host

`make host` builds `build/host`, a Linux executable that links the kernel's portable C files with `test/host.c` and the same `build/rootfs.o` and `build/docfs.o`. It reads lines from standard input, evaluates each as omega, and prints the result stack after it. It has `@` commands: `@keys` queues keys (`up`, `down`, `left`, `right`, `enter`, `esc`, `space`, `tab`, `ctrl-s`, `ctrl-q`, or the characters of any other token), `@screen` prints the 80 by 25 text screen, `@docs` runs `help_check()` and prints `N problems`, and `@readline` and `@dis` exist for the line editor and the disassembler.

    make host
    printf '@docs\n@keys right right down q\nwander\napps\n@screen\n' | build/host

The first line must print `0 problems`. `@keys` has to come before the program runs, because the harness has no real keyboard: when the program asks for a key that is not queued, the harness stops that line (`ran out of keys during: ...`). The queued `q` ends the loop. `@screen` then shows the final screen, where `apps` should list `wander`.

A definition typed into the harness must be on one line. Unit files may span lines because the parser reads the whole unit. The harness has no mouse, so `mouse?` is 0 there and the click branch is not exercised. `peek`, `time` and `date` do not work in the harness; programs that use them are checked in QEMU.

### Verifying in QEMU

    make
    qemu-system-x86_64 -kernel build/subverge.elf -m 256

Run `wander`, move with the arrows, and click in the QEMU window to check the mouse branch. Press `q`, and check that the prompt and the tab label come back. Press Ctrl-C while it runs and check that `! interrupted` is printed. Check `apps` and `'wander help`. A drive that was installed from an older build holds its own copy of root and does not show the new unit (see Persistence in an installed system above). `test/qdrive.c` and the `*.qd` scripts drive a QEMU instance for automated runs.

## The learn tutorial

`learn` is the guided tour of the language. It is the whole of the unit `learn` in `root/80-learn.om`, and the lessons are data in the same file.

### Structure

    [ [
      [ "Title" "  Body text, lines already broken with \n." "a line to run" ]
      ...
    ] ] :lessons

`lessons` is a quote that pushes a list of lessons. A lesson is a list of exactly three strings:

| Position | Name in `lesson` | Use |
|---|---|---|
| 0 | `ttl` | the heading, printed in colour 11 |
| 1 | `body` | the explanation, printed as it is |
| 2 | `task` | the line offered to the user. An empty string means no task |

There are 47 lessons. `lesson` takes the index of the first lesson to show, `learn` is `0 lesson`, and `28 lesson` starts at index 28. The numbers shown to the user are one more than the index: the header is built as `learn  <i + 1> of <n>`, so lesson index 0 is displayed as 1 of 47.

### The loop

For each lesson `lesson` does the following.

1. `wipe nocursor`, then the header (`header`), the title and the body.
2. If `task` is not empty, it prints `Run this, or type your own line:` and the task, then reads a line with `empty "  > " ask`. A non-empty line is evaluated with `eval` inside `try`. If it fails, the stack is restored to the snapshot taken before (`depth list { snap }` and `empty snap spread`), so a failed line does not corrupt the lesson. The stack after the line is printed.
3. It prints `Space next, b back, q stop.` and waits with `key`. `quit-key?` ends the tour. `b` (code 98) goes back one lesson when `i` is above 0. Any other key goes forward, and after the last lesson the tour ends.

At the start `lesson` saves the user's stack: `depth list { mine }`, then `empty`. At the end it clears the stack and restores it with `mine spread`, so the tour does not disturb what the user had.

`learn` runs as one long line. That has two effects the lessons mention: the definitions the tour's examples make are in the tab as usual, and `back` after `learn` goes back over the whole tour as one step.

### Width and format limits

- The screen is 80 columns wide. Body lines are indented by two spaces and broken by hand with `\n`. The longest line in the file is 73 characters including the two spaces; keep new lines at 76 or fewer.
- The longest body in the file has 6 lines. The lesson screen also holds the header, the title, the task block, the line the user types and the key prompt in 24 rows, so a body longer than that needs a check on the screen.
- The task is printed after four spaces, so it must fit in 76 characters. The longest in the file is 63. A quote or string inside a task is written with `\"` in the source.
- A body contains `\w` and `\A` for omega and aleph. A literal backslash is `\\`.
- A lesson with an empty task string shows the body and goes straight to the key prompt (lessons Undo, Persistence and Where next).
- The title is one line and is also what makes the header (`learn  3 of 47`) context; keep it short (the longest is 22 characters).

### Adding a lesson

1. Choose the position. A lesson belongs next to the one it builds on, because the list is read in order and the numbers shift for all that follow. `28 lesson` in the help text of `lesson` then points to a different lesson, so check that example.
2. Add a three-string list at that place in `root/80-learn.om`, or in a running system with `'lessons open`.
3. Write the body with real line breaks as `\n` and a two-space indent.
4. Write a task that works on a fresh tab, or an empty string. If the task needs a definition from an earlier lesson, say so in the body.
5. Run it: `printf '@keys space space q\nlearn\n@screen\n' | build/host`, or `N lesson` in QEMU, where `N` is the index.
6. Check the tour pages in `doc/` that mention the lesson count or a lesson by number, and check the text of the `learn` row in `apps`.

The last lesson, `Where next`, names `root/80-learn.om` and `'learn open`. The lessons `Registering it in apps`, `Checking the entry` and `Root units` describe the same steps as the section Writing a program; change them together.

## Themes and logos

### The themes table

Themes are the array `themes[]` in `kernel/vga.c`, declared in `kernel/vga.h` as `struct theme { const char *name; u32 rgb[16]; }`. The array ends with an entry whose name is `NULL`. Each entry has the name and 16 colours as `0xRRGGBB`. The comment above the table gives the roles, in index order, and `kernel/vga.h` has the enum `C_BG` to `C_CAT`:

| Index | Name in the table comment | Enum | Typical use |
|---|---|---|---|
| 0 | bg | `C_BG` | background |
| 1 | bar | `C_BAR` | top bar, selected rows, code in the pager |
| 2 | green | `C_GREEN` | |
| 3 | teal | `C_TEAL` | code text in the pager |
| 4 | red | `C_RED` | |
| 5 | mauve | `C_MAUVE` | page titles, visited links |
| 6 | peach | `C_PEACH` | selected link, quote bars |
| 7 | text | `C_TEXT` | default text |
| 8 | dim | `C_DIM` | hints, secondary text |
| 9 | blue | `C_BLUE` | word links |
| 10 | lgreen | `C_LGREEN` | success messages |
| 11 | sky | `C_SKY` | headings |
| 12 | lred | `C_LRED` | errors, unvisited links |
| 13 | pink | `C_PINK` | |
| 14 | moon | `C_MOON` | accent |
| 15 | cat | `C_CAT` | brightest text |

The themes that exist are `dusk` (index 0, the one `vga_init()` selects), `raw`, `paper`, `amber`, `phosphor` and `haelide`.

`vga_theme(n)` checks `n` against the number of entries and, if valid, writes all 16 colours to the VGA DAC through `vga_rgb(i, rgb)`. That function keeps the top six bits of each channel (`rgb >> 18`, `>> 10`, `>> 2`, each masked with `0x3F`) and writes them to port `0x3C9` after selecting the register with port `0x3C8`. The register for colour `i` is given by `dac_index()`: `i` for 0 to 5, `0x14` for 6, `7` for 7, and `0x38 + i - 8` for 8 to 15. These are the VGA attribute palette entries of the standard text-mode attributes, so the theme changes the colour behind a number that is already on the screen. The same table is loaded into the DAC when graphics mode starts (`b_gfx()` in `kernel/hw.c`) and restored by `gfx_leave()`.

### Adding a theme

1. Add an entry to `themes[]` before the terminating `{ NULL, { 0 } }`. Give it a lower-case name that is a valid symbol and 16 values in the order above.
2. Keep the existing entries in place. The index of the current theme is stored on the drive (`struct state_header.theme` in `kernel/persist.c`), so reordering changes what an installed system boots with.
3. Check that the contrasts are usable: colour 7 on 0 for text, 8 on 0 for hints, 1 as a background behind 7 and 14, 12 on 0 for errors and 9 on 0 for word links.
4. If the theme should bring a logo, define `logo-<name>` in `root/10-sys.om` (next part) and its row in `help.c`.
5. Document it in `doc/themes.md`, in the section that lists the themes.
6. Build, run `themes` and `'name theme`, and look at `colors`, `sys`, `docs` and `top` in it.

`'name theme` (`b_theme()` in `kernel/hw.c`) searches `themes[]` by name. A match does three things: if a word `logo-<name>` is defined, the logo becomes that logo; otherwise, if the current logo has the name of the theme that is being left, the logo goes back to `subverge`; then `vga_theme(i)` is applied and `persist_save_theme()` writes the theme index and the logo name to the header of the state area. An unknown name fails with `<name> isn't a theme, type themes to see them`. `themes` lists the names with `>` on the current one and prints the 16 colours as blocks. `theme@` leaves the current name.

## The help pages in doc/

The in-system help is a set of markdown files in `doc/`, shown by the pager in `kernel/doc.c`. A page is read from memory. Nothing is read from a drive, and an installed drive does not hold the pages. A page changes by editing its file and rebuilding.

### From files to the pager

    build/docfs.bin: $(sort $(wildcard doc/*.md)) | build
        @for f in $^; do printf '#>> %s\n' "$$(basename $$f .md)"; cat $$f; printf '\n'; done > $@

The build writes `#>> <file name without .md>`, the file, and a newline for each file in `sort` order, and links the result as `_binary_build_docfs_bin_start` and `_end`. The page name is the file name. `index_pages()` in `kernel/doc.c` scans the blob once for lines that begin with `#>> `, stores the name (at most 39 characters) and a pointer to the text, and computes the length of each page from the start of the next one. Page files therefore must not contain a line that starts with `#>> `. The table `pages[400]` holds at most 400 pages; the tree has 103.

The words `docs` (opens `index`) and `doc` (`"name" doc`) are in `doc_words[]`. `open_page()` falls back to `index` if the name is unknown and fails with `there is no page called <name>, type docs for the index` when `index` itself is missing.

### The markup dialect

`layout()` in `kernel/doc.c` reads the page line by line and decides the kind of block from the first characters of a line. The dialect is a subset of Markdown with a few additions.

| Block | Written as | Notes |
|---|---|---|
| Title | `# text` | Centred, in mauve. The first one becomes the title in the top bar (55 characters at most); a page without one is titled with its name |
| Heading 2 | `## text` | Moon colour. Also defines an anchor |
| Heading 3 | `### text` | Peach colour. Also defines an anchor |
| Deeper headings | `####` and more | Not headings. The line is a paragraph |
| Paragraph | consecutive text lines | Joined with single spaces and wrapped. It ends at a blank line or at a line that starts with `#`, `>`, a table row, a list item, a fence or `@pages` |
| List | `- `, `* `, `+ ` or `1. ` | Bullets are drawn as a dot (code `0xF9`), numbered items keep their number. Continuation lines are indented by at least two spaces. Nested lists indent by the leading spaces |
| Quote | `> text` | Drawn with a bar in the left margin, in peach. A quote that starts with `**Warning:**` has a light red bar |
| Code block, indented | four spaces | Only after a blank line (or the start). Lines with four leading spaces, blank lines inside are kept when the next line is indented again |
| Code block, fenced | a line starting with three backticks | Ends at the next line starting with three backticks. The info string after the opening fence is ignored, except `text` |
| Table | rows starting with `\|` | See below |
| Rule | three or more `-` or `*` at the line start | A line of box-drawing dashes across the page |
| Page list | the line `@pages` | A list of every page, sorted by title, each as a page link. Pages named `tour-*` and `index` are left out |

Blank lines: one blank line separates blocks. After a list, the first blank line in the source adds one blank line in the output, and the next block follows with the spacing of a normal block.

Inline markup, applied to paragraphs, headings, list items, quotes and table cells:

| Written | Result |
|---|---|
| `` `code` `` | teal text, no further markup inside, spaces are not break points |
| `**bold**` | moon colour |
| `*emphasis*` or `_emphasis_` | the markers are removed; the text is drawn in the surrounding colour. The opening marker must be at the start or after a space and must be followed by a non-space, and the closing marker must follow a non-space |
| `\x` | the character `x`, for any `x`. It is also processed inside a code span |
| `&lt;` `&gt;` `&amp;` `&#124;` | `<` `>` `&` `\|`, outside code spans only |
| `[text](target)` | a link; see below |

A `\|` inside a table cell needs the backslash or `&#124;`, because the row is split at the bar first.

### Code lines and `runnable()`

Every line of an indented block or of a fence that is not `text` is a candidate for a run link. `code_line()` first finds the note: the part of the line after the first run of three spaces. The part before it is the code. It becomes a link of kind run if `runnable()` accepts it. A runnable line is drawn on the bar colour in teal (`ATTR(C_TEAL, C_BAR)`), is selected with Tab like other links, and on Enter or a click the viewer closes, the text of the code part is copied to `doc_run` (200 bytes) and `omega_main()` evaluates it at the prompt after echoing it (`kprintf("%s\n", run)` and `eval_line(run)`).

`runnable(s, n)` takes the words of the code part, splits on spaces and brackets, and returns true when there is at least one token and every token is acceptable:

- a string between double quotes is skipped as a whole;
- a token that starts with a digit, or `-` followed by a digit, is a number and is accepted;
- a token starting with `'` or `:` is checked without that character, and `->` is skipped before the name;
- `{` and `}` are accepted;
- anything else must be a builtin (the interned name has a function) or a bound name in the current dictionary (`lookup()`).

If a word is unknown the line is plain teal text. This is why a command written in a page and not yet defined in the tab, or one with a typo, does not become a link. The check runs in the world of the tab that opens the pager, so a user's own definitions count. A fence with the info string `text` (three backticks followed by `text`) is never a link. Use it for output, for prompts that show `>` or for code that is not meant to be run. In an indented block use three spaces to separate a comment from the code; a note after the code is shown but not run. A line in a block is cut at the screen width (columns 4 to 79).

### Links

The target is the text between the parentheses. `inline_text()` determines the kind from the start of the target.

| Target | Kind | Example | Behaviour |
|---|---|---|---|
| `page` or `page.md` | page | `[keys](keys)` | opens the page `keys`. A trailing `.md` is removed |
| `page#anchor` | page and anchor | `[x](themes#graphics-mode)` | opens the page and scrolls to the heading |
| `#anchor` | anchor | `[x](#graphics-mode)` | scrolls to a heading of the current page |
| `?word` | word | `[dup](?dup)` | opens the generated page of the word `dup` |
| `?group:name` | group | `[math](?group:math)` | opens the generated list of the group `name`. It is a word link whose target starts with `group:` |
| `>code` | run | `[Snake](>snake)` | closes the viewer and runs `code` at the prompt |
| `http...` | external | `[HaliadeSYS](https://github.com/...)` | not a link. The text is shown plain, since the system has no network |

The tilde rule: in a run link, `~` stands for a space. A target cannot contain spaces in the source form used by the pages, so `[Timer](>90~timer)` runs `90 timer` and `[Hexview](>0xB8000~hexview)` runs `0xB8000 hexview`. Outside run links `~` is an ordinary character.

Anchors are made from `##` and `###` headings by `add_anchor()`: the text is lower-cased, spaces become `-`, and everything except `a-z`, `0-9` and `-` is dropped. The names are cut at 38 characters and the page keeps 64 anchors at most. `## Graphics mode` has the anchor `graphics-mode`. A link to an anchor that does not exist leaves the position unchanged.

If a link target does not exist (no such page, or a word without a page), `follow()` restores the previous page, position and selection, and nothing else happens. `make doccheck` finds the first case before the build (see below).

### Character set

The pager converts the page from UTF-8 to the single bytes of the screen font before layout (`to_font()`). Bytes below 0x80 are copied. Everything else is decoded and passed to `cp_of()`, which returns a font code or `?` for characters the font cannot show.

| Character | Code point | Font code | Becomes |
|---|---|---|---|
| omega | U+03C9 | 0x80 | omega glyph |
| aleph | U+2135 | 0x81 | aleph glyph |
| subscript 0 to 9 | U+2080 to U+2089 | 0x82 to 0x8B | subscript digit |
| o with diaeresis | U+00F6 | 0x94 | `ö` |
| right guillemet | U+00BB | 0xAF | `»` |
| middle dot | U+00B7 | 0xFA | `·` |
| superscript 2 | U+00B2 | 0xFD | `²` |
| epsilon | U+03B5 | 0xEE | `ε` |
| pi | U+03C0 | 0xE3 | `π` |
| less than or equal | U+2264 | 0xF3 | `≤` |
| greater than or equal | U+2265 | 0xF2 | `≥` |
| square root | U+221A | 0xFB | `√` |
| minus sign | U+2212 | `-` | ASCII hyphen |
| right single quote | U+2019 | `'` | ASCII apostrophe |
| right arrow, maps-to arrow | U+2192, U+21A6 | `>` | ASCII `>` |
| subscript k, modifier k | U+2096, U+1D4F | `k` | ASCII |
| subscript j | U+2C7C | `j` | ASCII |
| subscript n, superscript n | U+2099, U+207F | `n` | ASCII |
| superscript plus | U+208A | `+` | ASCII |
| superscript 3 | U+00B3 | `3` | ASCII |

Every other non-ASCII character is shown as `?`. The font is the table in `kernel/font.c`; adding a glyph needs a new code point mapping in `cp_of()` and the glyph itself. Most pages use ASCII only. The sequences `\w` and `\A` that the omega parser accepts in strings are not markup; in a page write the glyph itself or `omega` and `aleph0`.

## How a page is checked

### make doccheck

    make doccheck

runs `python3 test/doclinks.py`, a 17-line script. It reads every `doc/*.md`, finds each `](target)` with a regular expression, and reports a problem for:

- a page target (no `?`, `>`, `http` prefix) whose page name, after the removal of an anchor and a trailing `.md`, is not the name of a file in `doc/`. The names `word-index` and `a-to-z` are accepted as pages;
- a target that starts with `@` or `!`, which is not a link kind the pager knows.

It prints `file: target` for each problem and `N problems`, and exits with status 1 when there are any. Targets that start with `?`, `>` or `http` are skipped, as are anchor-only links.

It does not check:

- that the word of a `?word` link has an entry in `help.c`; this fails at run time by leaving the pager on the current page;
- that the anchor in `page#anchor` exists;
- that a code line is runnable, or that the example in a page works;
- links written in other ways: the regular expression sees only `](...)` with no `)` inside;
- table widths, line widths, or the characters used;
- the website copies of the pages in `sbvrg.github.io/src`.

## Writing and reviewing a page

A page is a file `doc/<name>.md`. The file name is the page name that `doc`, `docs` and the links use: lower case, digits and `-`, at most 39 characters. Add the name to the list in `doc/index.md`, where pages are grouped, unless it is a `tour-*` page. `@pages` in `index.md` lists everything else by title.

### Checklist for a page

1. The first line is `# Title`. It is one line, in title case or a short noun phrase, and it is what the pager shows in the top bar and in the `@pages` list (31 characters are kept in the list).
2. The page has one subject. If a second subject needs more than a paragraph, it is another page, and the two link to each other with `[text](page)`.
3. The page starts with the plain facts. It does not describe what the pager or the system is. It does not repeat what a linked page says.
4. Headings are `##` and `###` only. A heading is a noun phrase and its anchor (lower case, `-` for spaces) is short enough to link to.
5. Every cross-reference is a direct pointer, written as `see [keys](keys)`. The target is an existing file name. `make doccheck` must print `0 problems`.
6. Every word a reader may need is linked with `[word](?word)` the first time it is used on the page, and the word has an entry in `help.c`. A group is linked with `[math](?group:math)`.
7. Every example is an indented block (four spaces) or a fence. A code line that should run has all its words defined in the tab that reads it. A line that should not run (output, a prompt, code in progress) is in a fence marked `text`. A comment is separated from code by three spaces.
8. Every example was run in `build/host` or in QEMU, and the result in the text is the result that was printed. Words that crash or do not exist in the harness (`peek`, `time`, `date`) are tried in QEMU.
9. Tables have a header row and a separator row. The widths are checked by counting displayed characters: the sum of the column widths plus two per column is at most 74. Put long text in the last column, which wraps. Keep header cells short.
10. Text lines are not wrapped by hand in paragraphs. Paragraph text is on one line in the source. Code lines are at most 76 characters (columns 4 to 79).
11. The characters are ASCII, or from the list in the character-set table above. A character outside that list appears as `?` on the screen.
12. Do not use raw HTML, images, footnotes or reference-style links. They are not part of the dialect. A URL is not a link in the system.
13. The `&lt;`, `&gt;` and `&amp;` entities are needed only outside code spans; inside a code span write the character.
14. Read it in the pager: `"name" doc` in QEMU. Tab through the links, check that run lines are teal on the bar, that visited colours change, and that Backspace returns.

### Pages on the website

The in-system pages and the website pages in `src/*.md` of the site repository are different files with the same format. The site pages are built by `build.sh` into HTML and carry the site header and footer. A page that exists in both places is changed in both. In-system links name the page (`[keys](keys)`), and the site pages link with `name.md`. The pager removes `.md` from a page link, so `[keys](keys.md)` also works in `doc/`, and `doc/themes.md` already uses that form. See [docfs](docfs.md) and [help](help.md).

## Checklist for root and page changes

1. Decide the unit. A new program goes in the unit of its kind or in a new file `root/NN-name.om` that starts with `#>> name` and ends with a newline. The prefix puts it in the build order, and the units it uses come before it.
2. Define every word above its first use, and keep helpers next to the program that uses them. Take arguments on the stack, and use `{ }` locals for the body.
3. A full-screen program starts with `"name" title wipe nocursor`, loops on `[ going ] [ ... ] while`, ends the loop on `quit-key?` or on any key, and finishes with `wipe "omega" title`. Read keys with `key?` or `waitkey`, and release `alloc` blocks with `free` before it returns.
4. Register user-visible programs in `app-list` in `root/05-apps.om` with a description of at most 25 characters.
5. Add a row in `kernel/help.c` for every new root word, with a group from `groups[]`, an effect of at most 15 characters and a text of at most 52. Helpers go in the group `helpers`.
6. If the word is new to the tour or changes a lesson, edit `root/80-learn.om`: three strings per lesson, body lines of at most 76 characters, a task that fits in 76. Check that `28 lesson` in the help text of `lesson` still points where it should.
7. For a new theme, append to `themes[]` in `kernel/vga.c` without reordering, and add a `logo-<name>` word and its help row if the theme has a logo. For a new logo, add `logo-<name>` to `root/10-sys.om` and a helper row.
8. Run `make host`, feed the program and its keys to `build/host` with `@keys`, check `@screen`, and run `@docs`. It must print `0 problems`.
9. Run `make`, boot `build/subverge.elf` in QEMU with no installed drive, and run the program with the keyboard and the mouse. Press Ctrl-C and check that it stops with `! interrupted`.
10. Check a failed edit: break the unit with `'name open`, confirm the message `root unchanged, ...` and that `root` marks the unit as `(draft)`, then fix it.
11. Check `root`: the unit and its words are listed, and a unit with more than 96 names is split into units or checked for the missing names.
12. For a page, put the file in `doc/`, link it from `doc/index.md` or from a related page, link out to related pages and words, and run `make doccheck`. It must print `0 problems`.
13. Run every code line of the page in `build/host` or QEMU, and check the table widths, the line lengths and the characters against the lists above.
14. Open the page in QEMU with `"name" doc`, step through the links, and check the colours of run, word and page links.
15. If the change affects the numbers in the version strings of `os`, `kernel-name` or the `sys` shell line, change all three.
16. Update the matching site page in `sbvrg.github.io/src` when the behaviour it describes has changed, then rebuild the site with `build.sh`.

## The host harness

`make host` builds the omega interpreter and most of the kernel as an ordinary Linux program, `build/host`. The program is `test/host.c` (185 lines) linked with the kernel files named in `HOSTSRC` and with the two blobs the kernel normally carries, `build/rootfs.o` (the root units) and `build/docfs.o` (the help pages). Everything the kernel gets from hardware is replaced by a stub in `test/host.c`. The result runs one tab, reads lines from standard input and evaluates them with `eval_line`, the same function the shell calls.

    $ make host
    $ printf '[ dup * ] :sq\n7 sq\n@screen\n' | build/host

The compile line is

    gcc -DHOST -g -O1 -fno-builtin -no-pie -w -Ikernel -o build/host $(HOSTSRC) test/host.c build/rootfs.o build/docfs.o

`-DHOST` switches the few `#ifdef HOST` blocks in the kernel (listed below), `-g` makes the program debuggable with `gdb build/host`, `-fno-builtin` keeps gcc from replacing the kernel's own `memcpy` and `strlen` loops with calls to the libc ones, and `-w` silences warnings. The host build is not the place to look for warnings: the kernel build uses `-Wall -Wextra` and should stay free of them.

### What is faked

| Kernel facility | Real implementation | In `host.c` |
|---|---|---|
| boot information | `kernel/main.c` fills `struct bootinfo boot` from Multiboot | `boot = { 256 * 1024, 200 * 1024, "host" }`: 256 MiB of memory, a 200 KiB kernel, loader name `host` |
| heap | `heap_init` on the memory after the kernel, at most 64 MiB | `heap_init` over a 64 MiB static array, so the heap code in `kernel/mem.c` is the real one |
| screen | VGA text memory at `0xB8000` | `kernel/vga.c` is compiled with `HOST`, and `HW` points at `u16 host_screen[80 * 25]` instead; port writes in `vga.c` become no-ops through local `outb` and `inb` macros |
| keyboard | `kernel/kbd.c`, the PS/2 interrupt handler | `kbd_poll`, `kbd_get` and `kbd_init` read the ring `current->kb[64]` that `@keys` fills |
| time | the PIT at `HZ` 100 and `tick_count` | `fake_ticks`, which only `host_yield` increments, by one each call |
| idle and interrupt counters | `idle_ticks`, `irqn[]` | `idle_count()` returns `fake_ticks / 2`, `irq_count(0)` returns `fake_ticks`, every other `irq_count` returns 7 |
| `irq_set`, `timer_init` | the PIC and PIT setup | empty functions |
| `panic` | the red screen and `hlt` | prints `PANIC: message` and calls `exit(1)` |
| `cpu_brand` | `cpuid` leaves `0x80000002` to `0x80000004` | copies `Host CPU` |
| `yield` | `int $48` | `kernel/sched.c` under `HOST` calls `host_yield`, which advances the fake clock |
| JIT memory | `kmalloc_try` and `kfree` | `jit_alloc` is an `mmap` with `PROT_READ | PROT_WRITE | PROT_EXEC` of `n + 16` bytes; the first 8 bytes of the mapping store its length, and `jit_free` reads it back for `munmap`. The compiled code is real x86-64 that runs inside the host process |
| `font_init`, `font_save`, `font_restore` | VGA font plane handling in `kernel/font.c` | empty functions |
| persistence | `kernel/persist.c`: ATA, state header, slots | `persist_load` returns `NULL`, so nothing is ever restored; `persist_save_tab`, `persist_save_root` and `persist_save_theme` do nothing; `persist_home` returns -1 |
| persist words | `persist_words[]` | a table with `home` (pushes -1) and the no-ops `drives`, `ask`, `install-to` and `save` |
| irq-safe sections | `irq_save` and `irq_restore` with `pushfq` and `cli` | `kernel/task.h` under `HOST` defines them as empty inline functions |
| the mouse | PS/2 init and the interrupt handler in `kernel/mouse.c` | the part of `mouse.c` inside `#ifndef HOST` is left out, so `mouse?` pushes 0 and `mouse` pushes 0 -1 0 (cell column, cell row below the tab bar, buttons) |
| help check | n/a | `help_check()` in `kernel/help.c` exists only under `HOST` |

The four tab tasks are never started. `main` sets `current = &tabs[0]`, `tabs[0].entry = omega_main` and `active_tab = 0`, and calls `omega_init_world()` again to create the world for that tab. There is no scheduler loop, so a word that waits for something another tab would do cannot complete. A word that calls `yield` or `sleep` only moves the fake clock.

The registration order in `main` is the same as `kmain`: `core_words`, `hw_words`, `ord_words`, `root_words`, `jit_words`, `dis_words`, `help_words`, `doc_words`, `mouse_words` and `persist_words`, then `ord_init()` and `root_boot()`. If the root units fail to build, the harness prints `ROOT ERROR: message` before reading input. That line is the quickest way to find a syntax error in a file in `root/`.

### The source list

`HOSTSRC` in the Makefile is

    kernel/lib.c kernel/big.c kernel/omega.c kernel/words.c kernel/ord.c kernel/root.c kernel/hw.c
    kernel/line.c kernel/scrawl.c kernel/calc.c kernel/sysinfo.c kernel/mem.c kernel/vga.c
    kernel/sched.c kernel/jit.c kernel/dis.c kernel/help.c kernel/doc.c kernel/mouse.c

Five kernel files are left out, and `test/host.c` defines the symbols they would have provided.

| File | Why it is not built for the host | Replaced by |
|---|---|---|
| `kernel/main.c` | `kmain`, Multiboot parsing, the `sti` and `hlt` loop | `main` in `test/host.c` |
| `kernel/cpu.c` | IDT, PIC, PIT, exception handlers, `panic`, `cpuid` | `ticks`, `idle_count`, `irq_count`, `irq_set`, `timer_init`, `panic`, `cpu_brand` |
| `kernel/kbd.c` | scancode decoding on port `0x60` | `kbd_poll`, `kbd_get`, `kbd_init` |
| `kernel/disk.c` | ATA PIO on ports `0x1F0` and up | nothing, since the host build never calls into it |
| `kernel/persist.c` | `install`, `save`, the state header, `persist_snapshot` | the `persist_*` stubs and `persist_words` |
| `kernel/font.c` | the VGA character generator | `font_init`, `font_save`, `font_restore` |

A new file under `kernel/` belongs in `HOSTSRC` when it only manipulates memory and the `V` values of the interpreter. It stays out when it executes privileged instructions or talks to ports at load time, because the host program runs in ring 3 and the first `in`, `out`, `cli` or access to an unmapped address kills it with `SIGSEGV`. A file that is compiled for the host and still contains a hardware access in one word, such as `hw.c`, is fine as long as that word is not run. The same list is used by `make stress`, so a file added to one is added to both. The two targets differ only in `-DGC_STRESS` and the output name, and `stress` lists `build/rootfs.o` but not `build/docfs.o` as a prerequisite, so run `make host` once before the first `make stress` on a clean tree.

`kernel/help.c` includes `<stdio.h>` under `HOST` for the `printf` calls in `help_check`. The other `#ifdef HOST` blocks are `kernel/sched.c` (`yield`), `kernel/vga.c` (the screen array), `kernel/task.h` (`irq_save`), `kernel/jit.c` (`jit_alloc` and `jit_free` are external) and `kernel/mouse.c` (hardware part).

### How input is fed

`main` reads standard input with `fgets` into a 512 byte buffer and removes the last character of each line unconditionally. A final line without a newline therefore loses its last character, so end every script with `\n`. A line of 511 characters or more is split. The prompt line editor is not involved: each line goes straight to `eval_line`, which means the 200 character `LINE_MAX` of `readline` does not apply either.

For an ordinary line the harness writes `> ` in colour `C_SKY` and the line text in colour `C_TEXT` to the fake screen, runs `eval_line`, and prints to standard output

    [line as typed] stack contents

where the stack contents are the values of `W->cur.stack` printed with `repr`. This is the world after the line: if the line failed, the stack is the one from before it, as in the shell. Output that words produce with `kputs`, `.` and `say` goes to the fake screen, not to standard output, and shows up in `@screen` or in the final screen dump.

At end of input `main` calls `dump()` once more and returns 0.

### Directives

A line that starts with `@` is a directive. The match is by prefix with `strncmp`, so `@screenshot` is taken as `@screen`.

| Directive | Effect |
|---|---|
| `@screen` | prints the fake screen: a border line, 25 rows of 80 characters between `|` and a border line. Row 0 is the tab bar row (blank unless `title` or a tab switch drew it), rows 1 to 24 are the text area `VH` |
| `@keys k k k` | queues keys for the next line that reads them |
| `@readline` | calls `readline` on the world's history and prints `readline: N "text"`, or `readline: ran out of keys` |
| `@docs` | runs `help_check()` and prints `N problems` |
| `@dis name` | disassembles the compiled code of `name` |
| `@roundtrip` | saves the world as source, rebuilds it and compares |

Characters in `@screen` are the low byte of each cell, attributes are not shown. The printable range 32 to 126 is printed as it is. These cells are translated:

| Cell | Printed as | Meaning |
|---|---|---|
| `0x80` | `w` | the omega character |
| `0x81` | `A` | the aleph character |
| `0x82` to `0x8B` | `0` to `9` | subscript digits |
| `0xEE` | `e` | the epsilon character |
| `0xFA` | `.` | the middle dot used in progress bars |
| `0xFD` | `2` | the superscript 2 |
| `0xAF` | `>` | the prompt mark |
| `0xDB` | `#` | the full block |
| `7` | `*` | the bullet |
| anything else | `?` | |

### `@keys`

The rest of the line is split on spaces, and each token is turned into keys:

| Token | Key |
|---|---|
| `up`, `down`, `left`, `right` | `K_UP`, `K_DOWN`, `K_LEFT`, `K_RIGHT` |
| `enter` | `'\n'` |
| `esc` | 27 |
| `space` | `' '` |
| `tab` | `'\t'` |
| `ctrl-s` | `CTRL('s')` |
| `ctrl-q` | `CTRL('q')` |
| any other token | every character of the token, in order |

A token such as `abc` queues three keys, and a space between words needs the token `space`. The keys that the harness cannot produce are Backspace, Ctrl-C, Home, End, Page Up, Page Down, Delete, Shift-Tab and the mouse. A token like `home` would type the letters `h`, `o`, `m` and `e`. The queue is the 64 slot ring in `current->kb`, filled by `key()` without a full check: more than 63 keys queued before they are read overwrite the oldest.

Keys stay queued across lines until something reads them, so `@keys` goes before the line that needs them:

    @keys a b enter
    @readline

prints `readline: 2 "ab"`.

### `@dis` and `@roundtrip`

`@dis name` looks up `name`, and if it is a quote that has been compiled it writes the machine code to `build/dis.bin` and the listing from `dis1()` to `build/dis.txt`, one `offset: mnemonic` line per instruction. A quote is compiled when it runs for the second time, so run it a few times first:

    [ dup * ] :sq
    10 [ 5 sq drop ] times
    @dis sq

If the word has no code the harness prints `@dis: no code`. The directory `build/` must exist.

`@roundtrip` calls `omega_source` on the current world and prints `---- saved world (N bytes) ----` followed by the text. It then creates a fresh world with `W->restoring = 1`, evaluates the text in it, saves that world again and prints `roundtrip MATCHES` or `roundtrip DIFFERS` with the second text. This is the code path `install` and `save` use to write a slot, and a value type that does not survive it shows up here. The old world is dropped and not freed.

`@docs` is the docs check described above.

### What cannot be tested on the host

| Word or area | What happens in `build/host` |
|---|---|
| `peek`, `peekd`, `peekq`, `poke`, `poked`, `pokeq` | The word dereferences the address in the host process. `0 peek` ends with `SIGSEGV` (exit status 139), and an address inside the program's own mappings reads host memory |
| `in`, `out`, `ind`, `outd` | the `in` and `out` instructions fault in ring 3, so the process is killed |
| `time`, and `date`, which is a root word that calls it | `hw.c` reads the CMOS through ports `0x70` and `0x71`; the process is killed |
| `gfx`, `gfx-off`, `dot`, `box`, `window` | `gfx` scans PCI through ports `0xCF8` and `0xCFC` and is killed. The drawing words refuse to run while `gfx_on` is 0 with `graphics mode is off, run gfx first` |
| `pci`, `pci@`, `pcils`, `beep`, `cr`, `halt`, `reboot` | port or control register access, killed or meaningless |
| `mouse`, `mouse?`, and the mouse in the help viewer and `scribble` | no PS/2 driver; `mouse?` is 0 |
| `install`, `install-to`, `drives`, `save`, saved worlds | stubs; nothing is read from or written to a disk. `@roundtrip` tests the text form instead |
| tab switching with F1 to F4, the tab bar clock, the activity star | only one tab exists and `draw_tabbar` reads the CMOS clock through the host's `inb` stub, which returns 0 |
| interrupt-driven behaviour: `idle`, `irqmon`, Ctrl-C, preemption | `kbreak` is never set, since the keyboard handler is not there, so Ctrl-C handling is only testable in QEMU |
| timing: `ticks`, `uptime`, `bench` | the clock advances only inside `yield`, so figures say nothing about speed |
| the fault handler: `page fault at ...`, `your last line was dropped` | a real fault kills the host process instead of restarting the tab |
| graphics mode and the font | `gfx_on` never becomes 1 |
| the machine-specific parts of `sys`, `top`, `memls` | they run, with the fake values above |

Words that need none of these run the same as on the machine: arithmetic, bignums, ordinals and cardinals, lists and strings, quotes and locals, transactions and `back`, the JIT and the disassembler, root units, the help table, the pager's layout of a page (`doc`), and `scrawl` driven with `@keys`.

Bugs that look like they are about the host harness are usually one of these: a key that cannot be sent, a line that needs a clock, or a word from the table above.

## GC stress builds

`make stress` builds `build/stress` from the same sources with `-DGC_STRESS`. Two things change:

| File | Normal build | With `GC_STRESS` |
|---|---|---|
| `kernel/omega.c`, `gc_point()` | collects only when `W->nobjs > W->gc_threshold` (at least 8192, and twice the live count after each collection) | collects at every call, when pinning is off and `W->nkeep <= 256` |
| `kernel/mem.c`, `kfree()` | the block goes back to the free list | the block is first filled with `0xDD` |

`gc_point` is called once per item in `run()`, once per tick in compiled code (`h_tick` in `jit.c`), and by a few words that allocate in loops. With stress on, a collection runs before every word. An object that is reachable only from a C local variable, a field the marker does not visit, or a `V` held across a call that allocates is freed at the first opportunity and overwritten with `0xDD`. The symptom is then immediate and repeatable:

- a value that prints as an enormous number (`0xDDDDDDDD` in a field) or as a string of `Ý` characters,
- a crash inside `mark` or `run`,
- `PANIC: double free` from `kfree`.

The rule that keeps a value alive is `keep(v)` before the call that may allocate and `unkeep(n)` after, as `b_times`, `b_for`, `b_while`, `b_each` and `b_map` in `kernel/words.c` do. `call()` itself keeps the quote it runs. The keep stack holds 256 entries, `W->keep[256]`, and collection is skipped while it is deeper than that. A new built-in that allocates a result, calls a quote and then uses the result needs a `keep` around the call. Run `make stress` and a few lines that use the word, with lists and strings as arguments, for any change to `kernel/omega.c` and for every new built-in.

    $ make stress
    $ printf '[ 1 2 3 ] [ 2 * ] map .\n[ 1 2 3 ] [ dup * ] each\n' | build/stress

The build takes about fifteen seconds. `build/stress` collects before every word, so it starts and runs slower than `build/host`.

## The QEMU driver

`test/qdrive.c` (228 lines, plain C, no libraries beyond libc) starts QEMU, talks to its monitor, and plays a script of key presses and screenshots. It is built by `make qdrive` into `build/qdrive`.

    $ build/qdrive script.qd -- qemu-system-x86_64 -cdrom build/subverge.iso -boot d -m 256M

The first argument is the script, or `-` for standard input. Everything after `--` is the complete QEMU command, starting with the program name. `main` checks that `--` is the second argument and that there are at least four arguments, and otherwise prints `usage: qdrive script -- qemu args...` and exits with status 2.

### How it starts QEMU

1. It builds the monitor address `unix:/tmp/qdrive.PID.sock,server,nowait` from its own process id.
2. It appends `-monitor <that address> -display none` to the arguments given, so a `-display` or `-monitor` of your own is overridden by these two (QEMU takes the last one).
3. It forks. The child redirects standard output and error to `/dev/null` and runs `execvp`. Nothing QEMU prints reaches the terminal, which includes a QEMU error about a bad option. If the script appears to do nothing, run the QEMU command by hand first.
4. The parent connects to the socket, trying every 50 ms up to 100 times (about five seconds). If it cannot connect it prints `qdrive: no monitor`, kills QEMU and exits 1.
5. It reads from the monitor until the `(qemu) ` prompt appears, then runs the script.
6. At the end it sends `quit`, waits 200 ms, sends `SIGKILL` and `waitpid`, and unlinks the socket.

`until_prompt` is used after every monitor command. It polls the socket in 50 ms steps and gives up after 200 steps in a row with no data, which is about ten seconds without any output, with `qdrive: monitor timeout`. Any failure goes through `die()`, which kills QEMU and removes the socket.

QEMU's answer to a monitor command is read and thrown away. `mon info registers` in a script therefore does not show the registers. To read monitor output, run QEMU with `-monitor stdio`, or with `-monitor unix:/tmp/m.sock,server,nowait` and connect with `nc -U /tmp/m.sock`.

### Script commands

A script has one command per line. The first word is the command and the rest of the line, after one space, is its argument. Empty lines and lines starting with `#` are skipped. An unknown command prints `qdrive: bad line: ...` to standard error and the script goes on.

| Command | Argument | Effect |
|---|---|---|
| `wait` | milliseconds | sleeps |
| `type` | text | sends each character as a `sendkey`, 45 ms after each key, without Enter |
| `cmd` | text, optionally `  ~ms` | types the text, sends `ret`, then sleeps 600 ms or the number after the `~` |
| `key` | one QEMU key name | `sendkey name` and a 45 ms sleep |
| `shot` | file name | takes a screenshot as a PNG |
| `mon` | monitor command | sends the line to the monitor and waits for the prompt |
| `quit` | | ends the script; QEMU is shut down |

For `cmd`, the marker is two spaces followed by `~` and a number, at the end of the line. `cmd 90 timer  ~2500` types `90 timer` and waits 2.5 seconds. A text that itself contains two spaces and a `~` would be cut at that point. `cmd` with no text only presses Enter, which the scripts use to leave a program (`cmd   ~300`).

### Typing

`type` converts each character with `keyname`:

- letters and digits are sent as they are, and an upper case letter as `shift-x`,
- a table maps punctuation: space is `spc`, `[` and `]` are `bracket_left` and `bracket_right`, `'` is `apostrophe`, `:` is `shift-semicolon`, `+` is `shift-equal`, `*` is `shift-8`, `<` and `>` are `shift-comma` and `shift-dot`, `"` is `shift-apostrophe`, `{` and `}` are `shift-bracket_left` and `shift-bracket_right`, `|` is `shift-backslash`, `~` is `shift-grave_accent`, and the others (`; = - . , / ^ & ! ? # @ _ \ ( ) %`) are mapped the same way for a US layout.

Two characters used in omega are not in the table: the backtick and `$`. They would be sent as a key named by the character itself, which QEMU rejects, so they must be sent with `key grave_accent` and `key shift-4`. The table covers a US keyboard, which is what the kernel's scancode table in `kernel/kbd.c` assumes.

`key` takes QEMU's names directly: `ret`, `spc`, `tab`, `esc`, `backspace`, `up`, `down`, `left`, `right`, `home`, `end`, `pgup`, `pgdn`, `delete`, `f1` to `f4`, `ctrl-c`, `ctrl-s`, `ctrl-q`, `alt-1` to `alt-4`, `shift-tab`, and any letter. `sendkey` accepts several keys with `-`, and the driver passes the string unchanged.

### Screenshots

`shot file.png` runs `screendump file.png.ppm` in the monitor, converts the PPM to a PNG with the converter inside `qdrive.c` (a PNG writer with CRC and Adler-32, using stored deflate blocks so it needs no zlib), and deletes the PPM. The text screen is 720 by 400 pixels, so a file is about 860 KB. It prints `shot file.png`. The target directory must exist: the scripts write to `build/`. A failed screendump stops the script with `qdrive: screendump failed`.

### Timing rules

The driver does not look at the screen, so every wait is a guess that must be longer than the OS needs. The values used by the scripts:

| Situation | Wait |
|---|---|
| ISO to prompt (GRUB with `timeout 0`, then the kernel and `sys`) | `wait 5000` at the start of the script |
| `-kernel build/subverge.elf` to prompt | `wait 2500` |
| a word that prints and returns | the default 600 ms, or `~300` to `~800` |
| opening `help`, `learn`, `apps`, `root`, `'name open` | `~800` to `~1500` |
| `install` | `~800`, then `0` at `~600`, then `yes` at `~6000` |
| a word that animates or counts (`snake`, `life`, `rain`, `irqmon`) | `~2500` |
| `[ 24 fib drop ] bench` | `~9000` |
| `count`, `supertask` | `~19000`, `~12000` |
| after leaving a program with `q` or `ctrl-c` | `wait 500` or `600` before the next command |
| after `gfx` | `wait 700` before the screenshot |

A script that types before the prompt is ready loses characters, since the keyboard handler only fills the 64 slot queue of the active tab. The 45 ms between keys is long enough that the queue does not fill while a word is busy, but a long-running word delays the processing of the keys behind it, so wait before the next `cmd`. Timings on a slow or loaded host machine need larger numbers.

## Writing a QEMU test

A script for a feature: boot the ISO, type a line, check the result in a screenshot.

    # sum
    wait 5000
    cmd empty wipe
    cmd 2 3 + .  ~400
    cmd 2 3 + 4 *  ~400
    shot build/t-sum.png

The steps:

    $ make iso
    $ make qdrive
    $ build/qdrive test/sum.qd -- qemu-system-x86_64 -cdrom build/subverge.iso -boot d -m 256M
    shot build/t-sum.png

Look at the PNG. `empty` clears the stack and `wipe` clears the screen, which makes a screenshot easier to compare to the previous one. The test for a failing line is the same with the error text as the thing to look for:

    cmd 1 0 /  ~300
    shot build/t-err.png

A script that needs a disk attaches a blank image and boots it twice, once to install and once on its own:

    $ make disk
    $ build/qdrive test/shots2.qd -- qemu-system-x86_64 -cdrom build/subverge.iso -boot d -hda build/disk.img -m 256M
    $ build/qdrive test/shots3.qd -- qemu-system-x86_64 -hda build/disk.img -m 256M

A test that uses `gfx` needs the Bochs display card, which is QEMU's default `-vga std`. A test that sends keys to an editor or the pager uses `key` for Tab, Enter, Backspace and the arrows:

    cmd docs  ~1200
    key tab
    key tab
    key ret
    wait 600
    shot build/t-doc.png
    key q

The driver can send a mouse movement through the monitor:

    mon mouse_move 80 48
    mon mouse_button 1
    wait 200
    mon mouse_button 0
    cmd mouse? . mouse . . .  ~400

`mouse_move` takes relative steps in QEMU's units, and `mouse_button` takes the button mask (1 left, 2 right, 4 middle).

A test is finished when the screenshot shows what the feature should show and a second run gives the same picture. Timing-dependent output (`uptime`, `top`, the tab bar clock, `rand`) differs between runs, so screenshots of those are not comparable pixel by pixel.

## Debugging recipes

| Symptom | Probable cause | What to do |
|---|---|---|
| Black screen after GRUB, nothing printed | The kernel did not start or died before `vga_init`. Causes: a stale `build/subverge.elf` in the ISO; a build with a different `CFLAGS` that emits SSE instructions (the kernel is built with `-mgeneral-regs-only`, and `cr4` is never set up for SSE, so one `movaps` is an invalid opcode before the IDT exists); a change to `boot/boot.asm` or `linker.ld` that moved the Multiboot header out of the first 8 KiB of the image | `make clean && make iso`; boot with `-kernel build/subverge.elf` to skip GRUB; run with `-d int,cpu_reset -no-reboot -D /tmp/q.log` and read the end of the log; GRUB itself reports `no multiboot header found` when the header is missing |
| Reboot loop, or the screen resets every second | A triple fault. An exception before `cpu_init()` installs the IDT (the first lines of `kmain`: `persist_snapshot`, `vga_init`, `font_init`) has no handler, and an exception inside a handler that itself faults escalates through a double fault (`double fault` in the exception table, vector 8) | `-no-reboot -d int,cpu_reset -D /tmp/q.log`; the last `check_exception` lines in the log give the vector and `CR2`; add the failing step with `-s -S` and `hbreak` |
| `! page fault at 0x... (rip 0x...)` | `isr_handler` found vector 14 and printed `CR2` and the faulting `rip` (other vectors print `name at rip 0x...`). Memory is identity-mapped for the first 4 GiB with 2 MiB pages and nothing above, so an address of 4 GiB or more faults, for instance `0x100000000 peek`. Address 0 is mapped and does not fault. The tab restarts at its prompt with `your last line was dropped`, and the world is as it was before the line | resolve `rip` with `info symbol`; if the address is in the kernel, the function named is the culprit; if it is a heap address, it is compiled code: run `jit-off` and repeat the line to confirm, then `'name xray` |
| A line hangs and Ctrl-C does nothing | `kbreak` is set by the keyboard interrupt for the active tab and read by `brk()`. It is polled in `run()` for each item, in the loop words (`times`, `for`, `while`, `each`, `map`, `fold`...), in `sleep` and `beep`, and by compiled code at each loop tick (`h_tick`). A built-in that loops without calling `brk()`, code with interrupts masked by `irq_save`, or Ctrl-C pressed in a tab that is not the active one are the cases where nothing is polled | switch tabs with F1 to F4, which still works, and use `reboot` in the stuck tab or close QEMU; add `if (brk()) break;` to the built-in's loop |
| A value full of `0xDD`, a huge number where a small one was expected, a crash in `mark` | An object was freed while it was in use: a missing `keep()` around a call that allocates. The fill is the `GC_STRESS` fill, so this is also how `make stress` reports it. A normal build shows it as random corruption later | `make stress` and run the line again; find the object held in a C local across a call to `call`, `run`, `str_new`, `quote_new` or `gnew` and add `keep(v)` and `unkeep(1)` |
| `PANIC: double free` | `kfree` found the block already free. Usually a block freed by hand and also reachable from a quote, or a `jit_free` of code that `jit_forget` already released | build with `make stress`, then break on `panic` in gdb |
| A word is missing from `help` | The word has no entry in the `docs[]` table in `kernel/help.c`, or the entry's group is not in `groups[]` | `printf '@docs\n' | build/host` names the word as `undocumented builtin: name` or `undocumented root word: name`. The same check reports entries for words that do not exist, a bad group, text over 52 characters and an effect over 15 |
| `'name help` shows a page with the wrong group | the `group` field of the entry; groups are listed in order at the top of `help.c` | edit the entry |
| Text vanishes when switching tabs | Output that bypassed the per-tab buffer. Each tab owns `term.buf` (80 by 24 cells). `vga_put` writes the buffer and, for the active tab, video memory too. `switch_tab` redraws video memory from the buffer, so anything written to video memory with `hw_put` or directly to `HW[]` is lost. Only the tab bar, `panic` and the pointer cell are meant to do that. Output from a task that is not active goes to its buffer only and marks the tab with `*` | write through `vga_put`, `vga_puts_at` or `kputc`; check that code in an interrupt handler does not call `vga_put`, since `current` there is the interrupted task and the text lands in its buffer |
| Garbled text, wrong colours or a wrong font after `gfx-off` | The text mode registers or the font were not restored. `gfx_leave` does the restore: `vbe(4, 0)`, `font_restore(saved_font)`, `vga_restore()` and the palette from the current theme, and clears `gfx_on`. It relies on `vga_save()` and `font_save()` having been called by `gfx` when it entered. A fault inside graphics mode leaves `gfx_on` set; the tab restarts without the screen being restored, until `gfx-off` or any tab switch (`switch_tab` calls `gfx_leave` first) | switch to another tab and back; check that new code that changes the mode goes through `gfx_leave` |
| Drawing words fail with `graphics mode is off, run gfx first` | `dot`, `box` and `window` check `gfx_on` | run `gfx` first; the check is in `hw.c` |
| `gfx` fails with `no Bochs display here, start QEMU with -vga std` | `b_gfx` scans PCI bus 0 for the device `0x1234:0x1111` and reads the VBE ID register `0xB0Cx` | start QEMU with `-vga std` |
| The mouse does not move | The pointer is drawn only after the first movement event. QEMU delivers pointer events to the guest only after the window grabbed the mouse (click in it, Ctrl-Alt-G releases) and never in `-display none`, where `mon mouse_move` can be used instead. `mouse?` is 0 when `mouse_init` failed: the controller did not answer within 100000 polls, or the reset `0xF6` or enable `0xF4` command was not acknowledged with `0xFA`. IRQ 12 is unmasked in `cpu_init` (`0xA1` mask `0xEF`) | run `mouse? .`; if it is 1, check `info mice` in the monitor; in the pager, events are posted only for a task whose `mouse_on` is set, which `doc.c` sets while the viewer runs; tab clicks work in every program |
| The keys go nowhere or into the wrong tab | `kbd.c` pushes to `tabs[active_tab]`, and `kbd_get` reads `current->kb`. The ring has 64 entries and drops keys when it is full | check `active_tab`; a word that runs for a long time and does not read keys lets the queue fill |
| `ran out of memory`, or a panic with the same text | `kmalloc` returns `NULL` only through `kmalloc_try`; `kmalloc` itself panics. Words that allocate on request use the `_try` form and `fail` | `stats` and `top` show the heap; the heap is at most 64 MiB, whatever `-m` says |
| An installed disk boots to a blank state | `persist_init` found no `SVSTATE1` header, or a slot whose checksum does not match | `install` again, or check that the image is attached with `-hda` or `if=ide` |
| An installed disk keeps old root code after an update | The saved root in slot 0 is tried first at boot and the built-in root is the fallback | `install` again after changing files in `root/` |
| `ROOT ERROR:` in the host harness, or `! root: ...` on the first screen | A root unit does not build. The message starts with the unit's name | `make host`, run `printf '' | build/host` and fix the unit named |
| A line works in `build/host` and not in QEMU | Compiled code: the host runs it too. Otherwise clock, ports or the machine | compare with `jit-off`; try the line twice, since compilation happens on the second run |

## Code conventions

### C

The C is C11 (`-std=gnu11`), built freestanding with `-ffreestanding -nostdlib -mgeneral-regs-only -mno-red-zone -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -fcf-protection=none -O2 -Wall -Wextra`. The tree builds without warnings and a change should keep it so.

| Rule | In practice |
|---|---|
| indentation | 4 spaces, no tabs; the `case` labels of a `switch` are at the same level as `switch` |
| braces | the opening brace on the same line as `if`, `for`, `while` and the function head; the closing brace of a function in column 0 |
| short bodies | `if (cond) stmt;` and `if (!need(2, "swap")) return;` stay on one line, and a body of one to three short statements can sit in braces on the same line (`if (!x) { fail(...); return; }`); long lines up to about 140 characters occur in the tables |
| declarations | local variables at the point of first use; `i64 a, b;` lists for related values |
| files | one subject per file; `#include "cpu.h"` first among the project headers where it is needed, then the others in alphabetical order |
| headers | `#pragma once` and nothing else as a guard |
| types | `u8 u16 u32 u64 i8 i32 i64` from `lib.h`, `size_t` for sizes, `V` for omega values, `bind`, `quote`, `str` for objects; `int` for small counts and flags |
| naming | lower case with underscores for functions and variables, `T_` for value types (`T_INT`), `O_` for object kinds, `K_` for key codes, `C_` for colours, upper case for macros and constants (`HZ`, `STK`, `NTABS`) |
| linkage | everything used by one file only is `static`; names shared between files are declared in a header or, for a few table symbols, with `extern` at the point of use |
| comments | `/* */` only, one to three words, lower case, no full stops, above or beside the line they describe (`/* yield */`, `/* PIT timer */`, `/* bright backgrounds, no blink */`). No `//` comments, no doc blocks, no `TODO` |
| section headers | `/* printing */`, `/* the world */` and similar, on a line by themselves, preceded by a blank line |
| magic numbers | hardware constants appear as numbers with a comment when they need one (`0x3C8`, `0xF8`); limits are macros at the top of the file (`#define NEV 16`) |

The pattern for a built-in:

    static void b_name(void) {
        i64 n;
        if (!pop_int("name", &n)) return;
        if (n <= 0) { fail("name needs a number above 0%s", ""); return; }
        push(I(n * 2));
    }

and the table at the bottom of the file:

    const struct builtin xxx_words[] = { { "name", b_name }, { NULL, NULL } };

Built-ins are `static void b_<name>(void)`. The suffix `q` stands for `?` (`b_keyq` for `key?`, `b_mouseq` for `mouse?`), `d` for the 32 bit variant (`b_peekd`), `off` for a `-off` word (`b_gfxoff`), `b_fail` and `b_help` have the name as written. A word is registered in the table of its file and in `help.c`. A word that is a symbol or a name with punctuation uses a plain C name. Arguments come from the stack through `need(n, "word")`, `want`, `pop_int` and `pop_str`, each of which calls `fail` with the word's name on a mismatch and returns 0. Results are pushed with `push(I(n))`, `push(S(str))` or `push(Q(quote))`. A built-in must stop when `W->err` is set, which `push` already does, and a loop that can run long must test `brk()`.

### Freestanding rules

The kernel is linked with `-nostdlib`. No libc is present, so none of `printf`, `malloc`, `strcpy`, `strchr`, `atoi`, `qsort`, `snprintf` or the `<stdio.h>`, `<stdlib.h>`, `<string.h>` headers can be used. `kernel/lib.h` includes `<stdarg.h>`, `<stddef.h>` and `<stdint.h>`, which are compiler headers and are fine. `lib.c` provides:

| Function | Notes |
|---|---|
| `memset`, `memcpy`, `memmove`, `memcmp` | byte loops |
| `strlen`, `strcmp`, `strncmp`, `strstr` | |
| `scopy(d, s, cap)` | copy with truncation; always terminates |
| `snfmt(buf, n, fmt, ...)` and `vsnfmt` | a small formatter, described below |
| `outb`, `inb` | inline port access in `lib.h` |
| `MIN`, `MAX`, `CTRL` | macros |

`kernel/mem.h` provides `kmalloc`, `kmalloc_try`, `kzalloc`, `kfree`, `krealloc`, `heap_used` and `heap_total`. `kmalloc` panics when memory runs out and `kmalloc_try` returns `NULL`. A block carries a 32 byte header, sizes round up to 16 bytes, and `kmalloc_try` disables interrupts while it walks the list. There is no floating point (`-mgeneral-regs-only`; SSE registers are never saved by the tab switch), no `long double`, and no static constructors. `-fno-pie` means absolute addresses, so code is position dependent at `0x100000` (`linker.ld`).

Since the red zone is disabled and the tab switch saves only the general registers, an interrupt handler may use the stack freely.

### Formatting output

`kprintf(fmt, ...)` formats into a 256 byte buffer and prints it with `kputs` at the current position of the current tab, in the current colour, wrapping at column 80. `snfmt` writes into a buffer and returns the length that the full output would have had. Both use the formatter in `lib.c`, which understands:

| Spec | Meaning |
|---|---|
| `%s` | string; `NULL` prints `(null)` |
| `%c` | character |
| `%d`, `%u`, `%x` | `int`, `unsigned`, hex; with `l` or `ll` (the loop accepts any number of `l`) the argument is 64 bit |
| width, `0` and `-` | `%5d`, `%02u`, `%-11s` |
| `%%` | any other character after `%` is printed as it is, so `%%` gives `%` |

It does not know precision (`%.3s`), `%i`, `%p`, `%o`, floating point or `*` widths. Use `%lx` with a `u64` cast for pointers. `%lu` takes a `u64`.

The colour of printed text is set with `vga_color(C_x)` before and `vga_color(C_TEXT)` after. The colours are the 16 constants in `vga.h`: `C_BG`, `C_BAR`, `C_GREEN`, `C_TEAL`, `C_RED`, `C_MAUVE`, `C_PEACH`, `C_TEXT`, `C_DIM`, `C_BLUE`, `C_LGREEN`, `C_SKY`, `C_LRED`, `C_PINK`, `C_MOON`, `C_CAT`. Their values come from the current theme.

### Error messages

A built-in reports an error with `fail(fmt, arg)`, which stores the text in `W->errmsg[96]` (so at most 95 characters) and sets `W->err`. The first failure of a line wins: later calls return at once. `fail` takes exactly one `%s` argument, and a message without a variable part passes an empty string, which is why the source has the `%s", ""` idiom:

    fail("that list is empty%s", "");
    fail("%s isn't defined", s->s);
    fail("alloc takes 1 byte up to 16M%s", "");

The shell prints the message as `  ! text` in `C_LRED`, undoes the line and prints nothing more. The rules the existing messages follow:

- one lower case sentence, no full stop, no `error:` prefix, no exclamation mark;
- the first words say what failed, either the word's name (`pick needs 0 or more`, `peek needs more values on the stack`) or the thing (`that list is empty`);
- the message says what was expected, not only what went wrong: `sort needs a list of numbers or a list of strings`, `rand needs a number above 0`;
- plain English and contractions as in the rest of the system (`isn't`, `can't`, `doesn't`); no abbreviations such as `arg` or `ptr` and no hexadecimal numbers unless an address is the point;
- a message that suggests a fix names the word to run: `graphics mode is off, run gfx first`, `no Bochs display here, start QEMU with -vga std`;
- the word's name comes from the first argument of `need`, `want`, `pop_int` and `pop_str`, so a failed pop reports the word that called it. Pass the name of the word the user typed;
- a root word uses `"text" fail`, which calls the same path.

Faults print `page fault at 0x... (rip 0x...)` or `name at rip 0x...`, followed by `your last line was dropped` in grey. These come from the CPU and are not written with `fail`.

Messages are also documented on the [errors](errors.md) page, which should list a new message when one is added that a user can reach.

### omega

The root units in `root/*.om` are omega source. The rules that the existing 13 files follow:

| Rule | In practice |
|---|---|
| file names | a two digit number and a name (`00-core.om`, `57-tools.om`); the files are concatenated in name order, so the number is the order in which units build and later units may use earlier ones |
| unit header | the first line is `#>> name`, the unit name, 24 characters at most; the second line is a `#` comment of a few words (`# program list`, `# logos, stats`) |
| definitions | `[ body ] :name`, one per paragraph, separated by a blank line; a long body is broken at word boundaries with two spaces of indentation |
| names | lower case, hyphens between words (`mb-iter`, `scribble-hint`, `todo-add`), a `?` ending for a predicate (`quit-key?`, `leap?`), a `>` in a conversion (`f>c`, `km>mi`), no upper case |
| locals | `{ a b }` at the start of a quote takes the values in stack order; use them when a word has more than two arguments or uses a value more than twice. Locals are dynamically scoped, so a local with the name of a word hides that word inside the calls made from it |
| stack comments | a `#` comment after the definition or above it lists the arguments, `# x y w pct c` for a word whose effect is not obvious |
| comments | `#` to the end of the line, one to three words (`# dates`, `# 0 is monday`), above the group of definitions or beside a line |
| strings | double quotes; `\n`, `\t`, `\e`, `\w` and `\A` are the escapes |
| data | a list is a quote that is not run: `[ 3 1 2 ]`, `[ [ "a" "b" ] ]` as the body of a word that returns a list |
| help | every word, including helpers, has an entry in `kernel/help.c` (a root word without one is reported by `@docs`); a helper goes in the `helpers` group |

A unit file is plain text, so it can be typed into a prompt as well. When a root word is changed, check it twice in `build/host`, since the second run is the one the JIT compiles, and look at it in QEMU if it draws on the screen.

### The help pages

The pages in `doc/*.md` are linked into the kernel by the Makefile: each file is written to `build/docfs.bin` after a header line `#>> name` where the name is the file name without `.md`. `make doccheck` checks their links. They are read by the pager in `kernel/doc.c`, which handles `#`, `##` and `###` headings, paragraphs, lists, tables, indented code and the links `[text](page)`, `[word](?name)`, `[line](>code)`. The pages are the in-system version of the site's pages.

## Reporting bugs and sending patches

### A bug report

Bugs go on the [issue tracker](https://github.com/texivi/Subverge/issues), one bug per issue (see [bugs](bugs.md)). A report that a developer can act on contains:

| Item | How to get it |
|---|---|
| the version | `sys` shows the OS, kernel and shell versions; for a source build, `git rev-parse --short HEAD` as well |
| the exact line | copy it; a screenshot shows it with the error and the tab bar |
| the exact error | the red text, including a fault message with its `rip` and address |
| what was expected | one sentence |
| the QEMU command line, the QEMU version | `qemu-system-x86_64 --version`; many boot and display problems come from a flag |
| live ISO or installed disk, and how the disk is attached | `sys` shows which; `drives` lists what the kernel found |
| whether it happens after a fresh boot, with no disk | the saved root and worlds of a disk can cause it |
| the theme and the tab, when it is about colours or the tab bar | |
| the result of `jit-off` and the line again, for a wrong value from a word that has run more than once | the compiled code is used from the second run |
| the result in `build/host`, when the bug is in the language | `printf 'the line\n' | build/host` and `@screen` |

For a fault, add the `rip` resolved with `gdb -batch -ex 'info symbol 0x...' build/ordinal.elf` against the ordinal.elf of the same build. For a line that hangs, say whether Ctrl-C and F1 to F4 worked.

### A patch

A patch is a pull request on [github.com/texivi/Subverge](https://github.com/texivi/Subverge). Before sending:

1. The change builds with `make` without warnings and with `make host`.
2. `printf '@docs\n' | build/host` prints `0 problems`.
3. `make stress` runs with the lines that exercise the change.
4. `make doccheck` prints `0 problems` when pages in `doc/` changed.
5. A change in behaviour has a line that shows it in the description, and the QEMU test or the screenshot where the change is visible.
6. A new or changed word has its entry in `kernel/help.c`, its page text in `doc/` if the page lists it, and its row in the [all words](all-words.md) page of the website.
7. A change that touches `boot/` or the interrupt code is tested in QEMU with `-no-reboot`, since the host harness does not run it.
8. The code follows the conventions above: 4 spaces, one to three word comments, `static` functions, `b_` names for built-ins, error messages as one lower case sentence.

The commit message of a patch is a short imperative line.

## Pull requests

Open a pull request on [GitHub](https://github.com/texivi/Subverge). Describe the change, include the line you tested it with, and make sure `make stress` passes and the docs check prints `0 problems`. A change that adds or alters a word changes the help table and the [all words](all-words.md) page in the same request, and a change that alters behaviour changes the page that describes it.

Keep to the style of the file you are editing: its names, its comment density and its habits. The C is plain C11 with no macros that hide control flow, comments are one to three words, and code does not use anything the freestanding environment lacks.

## Licence

Subverge is released under the [GPL v3](https://www.gnu.org/licenses/gpl-3.0.html). A contribution is released under the same licence.
