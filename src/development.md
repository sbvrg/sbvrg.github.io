# Development

This page describes how Subverge is built, how the pieces of the source tree fit together, how the documentation is made and where each kind of change goes. It is meant for people who want to change Subverge. See [testing](testing.md) for the tests, [source layout](source-layout.md) for the files, [writing a built-in](builtins.md) for C words and [internals](internals.md) for how the running system is put together.

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

The files in `kernel/` are listed in [source layout](source-layout.md).

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

See [testing](testing.md) for each of them and for `qdrive`, which types into a running QEMU and takes screenshots. Run `make host`, `make stress`, the docs check and `make doccheck` before every commit.

### The docs check

    $ printf '@docs\n' | build/host

must print `0 problems`. It compares the table in `kernel/help.c` with the words that exist, and fails when a word has no entry, an entry has no word, a group is unknown, a description is longer than 52 characters or a stack effect is longer than 15. It checks the table that `help` reads and that the word pages in the help viewer are made from. The pages in `doc/` are checked by `make doccheck`; see [Checking the pages](#checking-the-pages).

## Adding a word

Built-in words live in the `*_words` tables at the bottom of their C files ([writing a built-in](builtins.md)). Root words live in `root/` and are written in omega. Either way the word needs an entry in `kernel/help.c`, and the website needs a row in [all words](all-words.md).

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

## The help pages

The help pages are the documentation of Subverge as it is read inside the system. They are files in `doc/`, one markdown file per page, and the build links all of them into the kernel. They are not read from a disk, so they are there on the live ISO, they always match the build that shows them and they cannot be edited in a running system. `docs` opens the index and `"name" doc` opens a page by name ([help](help.md), [docfs](docfs.md)).

### What a page is

A page is a text file with a name that is a word in lower case, such as `quick-start.md`. Its first line is `# Title`. The title is what the pager shows in its top line and what the index lists. The page name, without `.md`, is what links point at.

The pages are written in a small dialect of markdown that the pager lays out on the 80 by 24 text screen:

| Markup | Shown as |
|---|---|
| `# Title` | the title of the page, centred |
| `## Heading`, `### Heading` | headings, which can be the target of an anchor link |
| a paragraph | wrapped to the screen |
| `- item`, `1. item` | a list item with a hanging indent |
| `> quote` | a quotation with a bar at the left; `> **Warning:**` has a red bar |
| four spaces, or a fence | code, shown as it is and not wrapped |
| `\| a \| b \|` rows | a table, with columns sized to their contents |
| `` `code` ``, `**bold**` | code and bold text |
| `[text](target)` | a link |
| `@pages` on its own line | a list of every page, sorted by title |

A code block is also a link when every word in it exists. Selecting it and pressing Enter closes the viewer and types the line at the prompt. A fence with `text` after the backticks is never a link. Anything after three spaces in a code line is a note and is not run, so a line can show its result: `2 100 ^ .      1267650600228229401496703205376`.

### Links

The target of a link decides what it does.

| Target | Does |
|---|---|
| `page` | opens the page called `page` |
| `page#heading` | opens it and scrolls to the heading |
| `#heading` | scrolls to a heading of this page |
| `?word` | opens the page of a word |
| `?group:name` | opens the page of a group of words |
| `>line` | closes the viewer and runs the line at the prompt, with a tilde standing for a space |
| `http://...` | is shown but does nothing, since the system has no network |

An anchor is the heading in lower case with hyphens for spaces: `## Reading on` is `#reading-on`. A `.md` at the end of a page name is ignored.

### Generated pages

Four kinds of page are not files. They are made when they are asked for, from the table in `kernel/help.c`: the page of a word, the page of a group, `word-index`, which lists every word by group, and `a-to-z`, which lists them alphabetically. This is why a word needs a help entry and not a page: the entry is the page.

### How the pager works

`kernel/doc.c` finds the pages in the blob by their `#>> name` lines, converts the UTF-8 text to the single-byte characters of the screen font, lays the page out into rows of 80 cells, each with a link number, and then handles keys. A page is laid out once, when it is opened, and kept until the viewer closes. Links, headings and the current position are the only state. A link to a code line stores the line in a buffer that the shell reads after the word that opened the viewer has returned, so the line runs at the prompt like any typed line and its result stays on the stack ([prompt](prompt.md)).

Pages are limited to 4000 laid-out lines and 600 links. A page that needs more should be split.

### Writing a page

1. Create `doc/name.md` with a `# Title` first line.
2. Keep a page to one subject, and link to the page that explains anything else.
3. Link it from the index, `doc/index.md`, in the group it belongs to. A page that is not linked from anywhere except `@pages` is hard to find.
4. Check it.

### Checking the pages

`make doccheck` finds links to pages that don't exist and links of kinds the pager doesn't know. It prints each one and ends with the number of problems, which must be `0 problems`:

    $ make doccheck
    0 problems

It does not look at the prose. Open the changed pages in QEMU, which is the only way to see how a table wraps on 80 columns. Every code example is run in `build/host`, or in QEMU when it uses `peek`, `time`, `date` or anything else the host harness fakes.

## The website

The website is built from `src/` in the website repository. `src/*.md` are the pages, `src/template.html`, `src/home.html`, `src/header.html` and `src/footer.html` are the frame, `src/style.css` is the style, and `src/build.sh` turns them into the `.html` files at the root of the repository, which GitHub serves.

    $ bash src/build.sh
    built 99 pages

`md2html` converts each page, a `gawk` filter gives every heading an `id`, and a second filter builds the contents list that is shown at the top of every page with four or more headings. The root `.html` files are build output and are committed, since GitHub Pages serves the repository as it is. Edit `src/`, never the `.html` files.

### Pages on both sides

Most pages exist in both repositories, with different content: the website version has screenshots, links between pages as `.md` links, and the installation and hardware guides, while the version in `doc/` has no images and links that work in the pager. When a fact changes, change both. When a page is copied from `doc/` to the website, a link to a page the website doesn't have becomes plain text, `?word` links become code, and `>line` links become text.

### Screenshots

Screenshots are taken from QEMU with its monitor, at the default text size, and are saved in `images/` with a number in front, in the order they were added. Take them on a clean boot of the live ISO so that they show what a user sees.

## The boot sequence step by step

The kernel can be entered by three paths. GRUB and `qemu -kernel` use the Multiboot header in `boot/boot.asm`. An installed disk uses `boot/mbr.asm` and `boot/stage2.asm`, which do not read the header. All three arrive at the symbol `_start` in 32-bit protected mode with the same two registers set: `eax` holds `0x2BADB002` and `ebx` holds the physical address of a Multiboot information block. See [boot](boot.md) for the user-level description. This section is the order of events in the source.

### The Multiboot header

The header is the first thing in `.text`, because `linker.ld` places `*(.multiboot)` before `*(.text*)`. It is three 32-bit words.

| Word | Value | Meaning |
|---|---|---|
| magic | `0x1BADB002` (`MB_MAGIC`) | Multiboot 1 header magic |
| flags | `0x3` (`MB_FLAGS`, bits 0 and 1) | Align modules to 4 KiB, and provide memory information |
| checksum | `-(MB_MAGIC + MB_FLAGS)` | Makes the three words sum to zero |

Bit 16 (address fields) is not set, so the loader takes the load address and entry point from the ELF headers. That is the reason the build runs `objcopy -O elf32-i386 build/ordinal.elf build/subverge.elf`: both GRUB and `qemu -kernel` accept a 32-bit ELF carrying a Multiboot header. `build/ordinal.elf` is the 64-bit link of all objects. `build/subverge.elf` is the file that is booted, and it is the file the ISO contains as `/boot/subverge.elf`.

The header must lie in the first 8192 bytes of the file. It does, since `.multiboot` is the first input section of the first output section at 1 MiB.

### `_start`: 32-bit entry

`_start` is declared `bits 32` and runs with paging off and interrupts off.

1. `esp` is set to `boot_stack_top`. The stack is `boot_stack`, a `resb 262144` (256 KiB) region in `.bss`.
2. `edi = eax` and `esi = ebx`. These are the first two System V argument registers, so after the mode switch `kmain` receives the magic as its first argument and the information pointer as its second. No other code touches `edi` or `esi` until the call.
3. The page tables are built in `.bss`, aligned to 4096:

| Symbol | Size | Content |
|---|---|---|
| `pml4` | 4096 | Entry 0 points to `pdpt`, flags `3` (present, writable) |
| `pdpt` | 4096 | Entries 0 to 3 point to the four page directories, flags `3` |
| `pd` | 4096 * 4 | 2048 entries of 8 bytes, entry `i` is `(i << 21) \| 0x83` |

   Flag `0x83` is present, writable and page size (2 MiB). The loop at `.pd` writes the low dword as `i << 21 | 0x83` and the high dword as `i >> 11`, which is always zero for 2048 entries. The result is an identity map of the first 4 GiB with 2 MiB pages. Everything is supervisor, writable and executable. The map covers RAM, the VGA window at `0xB8000`, and a framebuffer BAR that sits below 4 GiB. `b_gfx` in `kernel/hw.c` refuses a framebuffer at or above `1 << 32` for that reason.
4. `cr3` is loaded with `pml4`. `cr4` bit 5 (PAE) is set. `EFER` (MSR `0xC0000080`) bit 8 (LME) is set with `rdmsr` and `wrmsr`. `cr0` bits 31 and 0 (PG and PE) are set. Long mode is now active, in compatibility mode until the far jump.
5. `lgdt [gdt64_ptr]` loads a three-entry GDT from `.data`:

| Selector | Descriptor | Meaning |
|---|---|---|
| `0x00` | `0` | null |
| `0x08` | `0x00AF9A000000FFFF` | 64-bit code, ring 0 (L bit set) |
| `0x10` | `0x00CF92000000FFFF` | data, ring 0, writable |

6. `jmp 0x08:long_mode` reloads `cs` and enters 64-bit mode.

### `long_mode`: 64-bit entry

`long_mode` loads `0x10` into `ds`, `es`, `fs`, `gs` and `ss`, sets `rsp = boot_stack_top`, executes `mov edi, edi` and `mov esi, esi` to clear the upper halves, and calls `kmain`. If `kmain` returns, `.hang` runs `cli; hlt` in a loop. `kmain` does not return.

There are no IST stacks, no TSS, and no ring 3. Every interrupt arrives on the stack of whatever was running, and the CPU pushes `ss` and `rsp` as well as `rflags`, `cs` and `rip`, because in 64-bit mode the five-word frame is always pushed. This is why `struct regs` in `kernel/task.h` ends with `rip, cs, rflags, rsp, ss`.

The compile flags in the `Makefile` follow from this: `-mno-red-zone` because an interrupt would overwrite memory below `rsp`, and `-mgeneral-regs-only` because no code saves or initialises SSE or x87 state. Floating point and vector code cannot be used in the kernel.

### `kmain`, in order

`kmain(u32 magic, u64 mbaddr)` in `kernel/main.c` runs with interrupts off until the final `sti`. The order matters, and each step depends on the ones before it.

| Step | Call | What it does |
|---|---|---|
| 1 | `persist_snapshot()` | Copies `_data_start` to `_data_end` into the static `snapshot[256 * 1024]` buffer in `kernel/persist.c`. It runs first so the copy holds the `.data` section as the loader left it. `install-to` writes this copy to disk. If `.data` is larger than 256 KiB the length is set to 0 and `install-to` fails. |
| 2 | `vga_init()` | Programs theme 0 (`dusk`) into the DAC, turns off blink so attribute bit 7 selects a bright background, sets the cursor shape, and fills all 2000 cells (80 by 25) of `0xB8000` with a space in `ATTR(C_TEXT, C_BG)`. |
| 3 | `font_init()` | Writes the glyphs for codes `0x80` to `0x8B` into font memory. |
| 4 | `cpu_init()` | Remaps the PIC, sets the interrupt masks, fills the IDT with the 49 stubs and executes `lidt`. |
| 5 | `read_multiboot(magic, mbaddr)` | Fills `boot.mem_k`, `boot.loader` and the `boot_mmap` table. |
| 6 | `boot.kernel_bytes = _kernel_end - _kernel_start` | Size reported by the `kernel` word. |
| 7 | `heap_init(...)` | Places the heap, see the memory map section. |
| 8 | `sched_init()` | Gives each of the four tabs an id, a blank text buffer in `ATTR(C_TEXT, C_BG)`, and the title `omega`. Sets `idle_task.id = -1`. |
| 9 | `persist_init()` | Probes the four ATA positions, finds the home drive, reads the state header, and applies the saved theme and logo name. |
| 10 | `omega_init_world()` | While `current` is still `idle_task`, this allocates a world for the idle task. The built-in words and the root units are registered into it. Each tab allocates its own world later in `omega_main`. |
| 11 | `register_words(...)` | In this order: `core_words`, `hw_words`, `ord_words`, `root_words`, `persist_words`, `jit_words`, `dis_words`, `help_words`, `doc_words`, `mouse_words`. |
| 12 | `ord_init()` | Creates the two pinned ordinal atoms `epsilon0` and `omega1` used by the ordinal words. |
| 13 | `root_boot()` | Loads the saved root source from slot 0 if there is one, otherwise the built-in `root/*.om` units linked as `_binary_build_rootfs_bin_start`. If the saved root does not build, the built-in one is used and the error is kept for `omega_main` to print. |
| 14 | `task_start(&tabs[i], omega_main)` for `i` in 0..3 | Allocates a 256 KiB stack per tab from the heap and builds the initial frame. |
| 15 | `switch_tab(0)` | Marks tab 0 active, copies its buffer to the screen, draws the tab bar. |
| 16 | `timer_init(HZ)` | Programs the PIT for 100 Hz and installs `on_tick` on IRQ 0. |
| 17 | `kbd_init()` | Drains the controller output buffer and installs `on_key` on IRQ 1. |
| 18 | `mouse_init()` | Runs the PS/2 auxiliary device setup. Installs `on_mouse` on IRQ 12 only if the device answers. |
| 19 | `sti` then `for (;;) hlt` | From here `kmain` is the idle task. |

The first timer interrupt arrives while `current == &idle_task`. `schedule` stores the interrupted frame as `idle_task.rsp`, which is a frame on the boot stack inside the `hlt` loop, and picks tab 0. All four shells start from `omega_main` on their first slice. Tab 0 additionally runs the `startup` word if it is defined and `sys` otherwise, or prints the system summary and the root error if the root failed to build.

### What `read_multiboot` reads

`read_multiboot` indexes the information block as an array of `u32`. Only the fields below are read.

| Index | Multiboot field | Flag bit | Use |
|---|---|---|---|
| `mb[0]` | flags | | Tested for the bits below |
| `mb[1]` | `mem_lower` (KiB) | 0 | Added into `boot.mem_k` |
| `mb[2]` | `mem_upper` (KiB) | 0 | Added into `boot.mem_k` |
| `mb[11]` | `mmap_length` | 6 | Byte length of the map |
| `mb[12]` | `mmap_addr` | 6 | Physical address of the map |
| `mb[16]` | `boot_loader_name` | 9 | Stored as `boot.loader`, a pointer, not a copy |

The defaults are `boot.mem_k = 64 * 1024` and `boot.loader = "unknown"`, from the initialiser of `boot` in `kernel/main.c`. When `magic != 0x2BADB002` the function returns after setting the default, so `mem_k` stays at 64 MiB. When flag bit 0 is set, `boot.mem_k = mem_lower + mem_upper + 384`. With `mem_lower` equal to 640 this is `mem_upper + 1024`, so `boot.mem_k` is the amount of RAM in KiB counted from address 0, and `boot.mem_k * 1024` is what the `kernel` word and `sys` report.

When flag bit 6 is set, the map is walked entry by entry. Each Multiboot map entry starts with a `u32 size` that does not count itself. The `base` (u64) is at offset 4, `len` (u64) at 12 and `type` (u32) at 20, and the next entry is at `p + size + 4`. At most 32 entries are copied into `boot_mmap[32]`, defined in `kernel/hw.c`, with the count in `boot_nmmap`. The `memmap` word returns them as a quote of `[ base len type ]` triples. The kernel does not use the map for any decision. The heap size comes from `mem_k` only.

The command line (flag bit 2, `mb[4]`) is not read, and neither are modules, the symbol table, drives, or the framebuffer fields. Nothing in the kernel parses boot arguments. Anything passed with `-append` or on a GRUB `multiboot` line is ignored.

### GRUB, `qemu -kernel` and the installed boot path

| | GRUB (ISO) | `qemu -kernel` | Installed disk |
|---|---|---|---|
| Started by | `multiboot /boot/subverge.elf` in `build/iso/boot/grub/grub.cfg` (`set timeout=0`) | QEMU's built-in Multiboot loader | BIOS, then `boot/mbr.asm`, then `boot/stage2.asm` |
| Reads the header in `boot.asm` | yes | yes | no |
| Needs a 32-bit ELF | yes | yes | no, stage2 gets a flat image |
| Information block | built by GRUB | built by QEMU's loader | built by stage2 at `0x5000` |
| `boot.loader` | the loader's name if flag bit 9 is set | the loader's name if flag bit 9 is set | `subverge stage2` |
| Memory map | from the loader, if flag bit 6 is set | from the loader, if flag bit 6 is set | INT 15h function `E820`, at most 32 entries |
| Home drive | none unless a second drive carries the signature | none unless a drive is attached | the boot drive |

The kernel does not check which loader started it. It tests only the magic and the flag bits it needs. The practical differences for a contributor are these.

- `make run` and `make run-install` boot with `-kernel`. The file `build/subverge.elf` is read by QEMU directly, so a change to `boot.asm` that breaks the Multiboot header is visible there and in the ISO, and a change that breaks only stage2's assumptions is visible only in `make run-disk`.
- The ISO drive is an ATAPI device. `identify` in `kernel/disk.c` rejects a device whose LBA mid and high registers are non-zero after IDENTIFY, so a CD-ROM never counts as a drive.
- Machine state at entry is whatever the loader leaves. The kernel reprograms the PIC and the PIT, reloads its own GDT, IDT and page tables, and clears the screen, and assumes nothing else.
- Stage2 enables the A20 line itself through port `0x92`. GRUB and QEMU deliver the kernel with A20 on.

### Stage2 and the information block it builds

Stage2 is described fully in the disk persistence section. The part that matters here is the contract with `kmain`. It sets `eax = 0x2BADB002`, `ebx = 0x5000`, and jumps to the entry address stored in its header. At `0x5000` it has cleared 88 bytes, then written: flags `(1 << 0) | (1 << 6) | (1 << 9)` at offset 0, `mem_lower = 640` at offset 4, `mem_upper` at offset 8, `mmap_length` at offset 44, `mmap_addr = 0x6000` at offset 48, and the pointer to `"subverge stage2"` at offset 64. These offsets are `mb[0]`, `mb[1]`, `mb[2]`, `mb[11]`, `mb[12]` and `mb[16]` as read by `read_multiboot`. A change to the set of fields `kmain` reads has to be made in both `boot/stage2.asm` and the loader assumptions above.

## The memory map

### Physical layout

All addresses are physical and equal to virtual addresses, since the page tables are an identity map of the first 4 GiB. See [memory](memory.md) for the user view.

| Range | What | Set up by |
|---|---|---|
| `0x00000` to `0x004FF` | real-mode vectors and BIOS data | firmware |
| `0x05000` | Multiboot information block (installed boot only), 88 bytes | stage2 |
| `0x06000` | E820 map copy, 24 bytes per entry, up to 32 entries (installed boot only) | stage2 |
| `0x07C00` | MBR, then the real-mode stack of stage2 | BIOS |
| `0x07E00` to `0x09DFF` | stage2, 8192 bytes | `mbr.asm` |
| `0x10000` | staging buffer for the kernel image (installed boot only) | stage2, `LOW_BUF` |
| `0xA0000` | VGA graphics window, also font memory while plane 2 is mapped | `kernel/font.c` |
| `0xB8000` | VGA text buffer, 80 by 25 cells of 16 bits | `kernel/vga.c`, `HW` |
| `0x100000` (1 MiB) | start of the kernel image, `_kernel_start` | `linker.ld` `. = 1M` |
| `_kernel_end` | start of the heap | `kmain` |
| PCI BAR 0 of device `1234:1111` | 640 by 480 8-bit framebuffer, `lfb` | `find_lfb` in `kernel/hw.c` |

### The kernel image

`linker.ld` lays out four sections, each aligned and padded to 4 KiB, starting at 1 MiB.

| Section | Contents | Symbols |
|---|---|---|
| `.text` | `*(.multiboot)` first, then `*(.text*)` | `_kernel_start`, and `_start` a few bytes in |
| `.rodata` | `*(.rodata*)` | |
| `.data` | `*(.data*)` | `_data_start`, `_data_end` |
| `.bss` | `*(COMMON)` and `*(.bss*)` | `_bss_start`, `_kernel_end` after it |

`.note*`, `.comment` and `.eh_frame` are discarded. The linker is invoked with `-z max-page-size=0x1000`, so sections are not padded to 2 MiB.

The `.bss` section holds, among other things, the page tables (24 KiB, 6 pages), the boot stack (262144 bytes), the `snapshot` buffer of `kernel/persist.c` (262144 bytes), the four `struct task` in `tabs[]` including their text buffers, and `idle_task`. These are all inside `_kernel_start` to `_kernel_end`, so `boot.kernel_bytes` and the heap start include them.

`.data` contains the rootfs and docfs blobs from `build/rootfs.o` and `build/docfs.o`, linked in with `ld -r -b binary`. They are exposed as `_binary_build_rootfs_bin_start`, `_binary_build_rootfs_bin_end` and the corresponding `docfs` symbols. The two installer blobs from `build/bootbins.o` (`_binary_build_mbr_bin_start`, `_binary_build_stage2_bin_start`) are linked the same way.

An installed disk stores the image as the bytes from `_kernel_start` to `_data_start` followed by the `snapshot` copy of `.data`, padded to a whole number of sectors. It does not store `.bss`. Stage2 copies the image to `load_addr` and clears memory up to `bss_end`.

The installed boot path stages the image in real mode at linear address `0x10000` and upward, in chunks of 64 sectors, before copying it to 1 MiB. Conventional memory ends at `0xA0000`, so the image, which is `(_data_start - _kernel_start) + (_data_end - _data_start)` bytes, has to fit in `0x90000` (589824) bytes. `install-to` checks only that the image is at most `LBA_STATE - LBA_KERNEL` (4032) sectors. Check the size of `.text`, `.rodata` and `.data` after any change that adds data, for example with `readelf -S -W build/ordinal.elf`. The ISO and `-kernel` paths are not affected by this limit.

### Stacks

| Stack | Size | Where | Used by |
|---|---|---|---|
| `boot_stack` | 262144 bytes (`resb 262144`) | `.bss` | `kmain`, which is the idle task, and the interrupt entry when the idle task is interrupted |
| per-tab stack | `KSTACK` = `256 * 1024` | heap, `kmalloc` in `task_start` | one shell and everything it calls, and the interrupt handlers that run while it is interrupted |

Interrupt handlers and the scheduler run on the stack of the interrupted task. There is no separate interrupt stack. Deep recursion in an omega word runs on the tab's 256 KiB stack. A stack overflow is not detected. There is no guard page, and the stack of a tab is an ordinary heap block, so an overflow corrupts the neighbouring heap block.

### The heap

`kmain` computes the heap range from `_kernel_end` and `boot.mem_k`:

    u64 heap_start = (u64)_kernel_end, ram_end = 0x100000 + (boot.mem_k - 1024) * 1024;
    heap_init(heap_start, MIN(ram_end - heap_start, 64ull * 1024 * 1024));

The heap therefore ends at the end of RAM as reported by the loader, or 64 MiB after `_kernel_end`, whichever is smaller. A machine with more RAM leaves the rest unused. With the default `mem_k` (used when the magic is not `0x2BADB002`) `ram_end` is 64 MiB, so the heap is smaller than 64 MiB by the size of the kernel image.

The allocator in `kernel/mem.c` is a first-fit list in address order. It has one global list head, `head`, and two counters, `used` and `total`.

    typedef struct blk { u64 size; u32 free, pad; struct blk *next; u64 pad2; } blk;

The header is 32 bytes (`sizeof(blk)`), which keeps every payload 16-byte aligned if the heap start is. Payload sizes are always multiples of 16.

| Function | Behaviour |
|---|---|
| `heap_init(start, size)` | Aligns `start` up to 16, subtracts the adjustment from `size`, creates one free block of `size - sizeof(blk)` bytes, sets `total = size` and `used = 0`. |
| `kmalloc_try(n)` | Rounds `n` up to a multiple of 16 (a request of 0 becomes 16). Under `irq_save`, walks the list, skips used blocks, calls `merge` on each free block, takes the first with `size >= n`. If the remainder after the request is at least `sizeof(blk) + 16` the block is split, otherwise the whole block is taken. Returns `NULL` when nothing fits. |
| `kmalloc(n)` | Calls `kmalloc_try` and calls `panic("ran out of memory")` on `NULL`. |
| `kzalloc(n)` | `kmalloc` followed by `memset` to 0. |
| `kfree(p)` | Accepts `NULL`. Under `irq_save`, panics with `"double free"` if the block is already free, otherwise marks it free, subtracts `size + sizeof(blk)` from `used` and calls `merge`. |
| `krealloc(p, n)` | `kmalloc(n)` for a null `p`. Returns `p` unchanged when the block is already at least `n` bytes, so it never shrinks. Otherwise allocates a new block, copies the old `size` bytes, frees the old block. It does not disable interrupts around the size check. |
| `heap_used()`, `heap_total()` | The `used` and `total` counters, which count headers as used. Returned by the `heap` word. |

`merge(b)` joins `b` with the following block while the next block is free and physically adjacent (`(u8 *)(b + 1) + b->size == (u8 *)b->next`). Coalescing happens forward only, at two points: in `kfree` for the freed block, and in `kmalloc_try` for each free block it visits. A free block that is followed by a used block and preceded by a free block is merged into its predecessor only when the allocation walk next reaches the predecessor. Fragmentation can therefore leave `kmalloc_try` failing for a large request while `heap_total() - heap_used()` is larger than the request.

`kmalloc_try` is for requests that can fail without being fatal. `persist_save_tab` and `persist_save_root` use it for their 1 MiB (`SLOT_SECTORS * 512`) buffers and skip the save silently if no such block exists. Everything else uses `kmalloc` and treats exhaustion as a panic.

The heap contents are not cleared by `kmalloc`. `kzalloc` clears. A build with `-DGC_STRESS` (the `stress` target) fills every freed block with `0xDD`, which is how use-after-free in GC roots is found.

`kmalloc`, `kfree` and `kmalloc_try` take `irq_save` because the timer can preempt a task in the middle of a heap operation and another task can then allocate. Interrupt handlers themselves never allocate. Code running with interrupts disabled for another reason can call the allocator, because `irq_save` returns the old flags and `irq_restore` puts them back.

## Interrupts

See [interrupts](interrupts.md) for the user view and the `irq` word. All of this is in `kernel/cpu.c` and `boot/boot.asm`.

### The IDT and the vector assignment

`idt[256]` is a static array of `struct idt_e` (16 bytes). Only entries 0 to 48 are filled. Each is a present 64-bit interrupt gate: selector `0x08`, IST 0, type/flags byte `0x8E`. An interrupt gate clears `IF` on entry, so every handler and the scheduler run with interrupts off. The remaining 207 entries are zero. A vector with a zero entry that is raised by hardware or by `int` causes a general protection fault (vector 13), which is treated like any other exception.

| Vectors | Source | Handler path |
|---|---|---|
| 0 to 31 | CPU exceptions | `isr_handler` calls `task_fault` |
| 32 to 47 | PIC IRQ 0 to 15 | `isr_handler`, `irqs[irq]`, EOI |
| 48 | `int $48`, the yield vector | `isr_handler` calls `schedule` directly |

`isr_table[49]` in `.data` holds the addresses of the 49 stubs `isr0` to `isr48`. `cpu_init` splits each address across the gate fields, `lidt` is done by `idt_load` in assembly, and nothing is enabled until `sti` at the end of `kmain`.

### The stubs

The stubs are generated by a `%rep 49` loop in `boot/boot.asm`. Each stub pushes an error code and the vector number, then jumps to `isr_common`. The CPU pushes a real error code only for vectors 8, 10, 11, 12, 13, 14, 17, 21, 29 and 30. For those the stub pushes only the vector number. For all other vectors, including every IRQ and vector 48, the stub first pushes a zero.

`isr_common` pushes `rax, rbx, rcx, rdx, rsi, rdi, rbp, r8` to `r15` in that order, so the lowest address holds `r15` and the layout matches `struct regs` in `kernel/task.h`:

    struct regs {
        u64 r15, r14, r13, r12, r11, r10, r9, r8, rbp, rdi, rsi, rdx, rcx, rbx, rax;
        u64 int_no, err;
        u64 rip, cs, rflags, rsp, ss;
    };

It then passes `rsp` as the first argument to `isr_handler`, and loads `rsp` from the return value. This is the whole context switch mechanism: `isr_handler` returns the stack pointer of the frame to resume. Returning its argument resumes the interrupted code. Returning another task's saved frame resumes that task. After restoring the registers, `add rsp, 16` drops the vector number and error code and `iretq` returns.

Segment registers are not saved. Every task runs with `cs = 0x08` and `ss = 0x10`, and the data segment registers are never changed after boot.

### `isr_handler`

    u64 isr_handler(struct regs *r)

| Condition | Action |
|---|---|
| `int_no < 32` | Formats a message and returns `task_fault(r, m)`. For vector 14 the message is `page fault at 0x%lx (rip 0x%lx)` with `cr2` and `rip`. For the others it is `<name> at rip 0x%lx` with the name from the `exc[32]` table, for example `general protection fault` or `invalid opcode`. The message buffer is 96 bytes. |
| `int_no == 48` | Returns `schedule(r)`. No EOI, no counter. |
| otherwise | `irq = int_no - 32`. Stores `last_rip = r->rip`, increments `irqn[irq]`, calls `irqs[irq]` if installed, sends EOI (`0xA0` first if `irq >= 8`, then `0x20`). Returns `schedule(r)` for IRQ 0 and `r` for every other IRQ. |

Only the timer causes a task switch. A key press runs `on_key`, which fills the ring and returns to the interrupted code. A shell blocked in `kbd_get` is made runnable by the ring becoming non-empty, but the scheduler sees that only at the next tick, so the delay from key press to wake-up is up to one tick (10 ms at 100 Hz).

Handlers are registered with `irq_set(irq, fn)`, which writes into `irqs[16]`. The handlers in use are `on_tick` (IRQ 0, installed by `timer_init`), `on_key` (IRQ 1, `kbd_init`) and `on_mouse` (IRQ 12, `mouse_init`). A handler takes no arguments, runs with interrupts off, on the stack of the interrupted task, and must not block, allocate, or call `yield`. The ones that exist call only `hw_put`, `switch_tab`, `draw_tabbar`, `mouse_move`, port I/O, and update fixed-size rings.

### The PIC

`cpu_init` initialises both 8259 chips with the standard four-word sequence.

| Port | Value | Meaning |
|---|---|---|
| `0x20`, `0xA0` | `0x11` | ICW1: edge triggered, cascade, ICW4 needed |
| `0x21` | `0x20` | ICW2 master: IRQ 0 to 7 become vectors 32 to 39 |
| `0xA1` | `0x28` | ICW2 slave: IRQ 8 to 15 become vectors 40 to 47 |
| `0x21` | `0x04` | ICW3 master: slave on IRQ 2 |
| `0xA1` | `0x02` | ICW3 slave: cascade identity 2 |
| `0x21`, `0xA1` | `0x01` | ICW4: 8086 mode |
| `0x21` | `0xF8` | mask: IRQ 0, 1 and 2 enabled |
| `0xA1` | `0xEF` | mask: IRQ 12 enabled |

The enabled lines are the timer (0), the keyboard (1), the cascade (2) and the PS/2 auxiliary device (12). Every other line stays masked, including the ATA lines 14 and 15. The ATA driver disables device interrupts itself by setting `nIEN` in the device control register (`outb(d->ctl, 0x02)` in `identify`) and polls the status register.

The EOI is sent before `schedule` returns a different frame, so a task switch inside the timer interrupt does not leave the PIC waiting. The yield vector has no PIC involvement and no EOI.

IRQ 12 is unmasked at boot even when no mouse is present. Without a device it never fires.

### The PIT and tick accounting

`timer_init(hz)` writes `0x36` to port `0x43` (channel 0, low byte then high byte, mode 3) and the 16-bit divisor `1193182 / hz` to port `0x40`. `HZ` is 100 (`kernel/cpu.h`), so the divisor is 11931 and a tick is about 10.0 ms. `timer_init` also calls `irq_set(0, on_tick)`.

`on_tick` does three things:

1. `tick_count++`. `ticks()` returns this value. It is the only clock the kernel keeps. `uptime` is `ticks() / HZ`, and `sleep` and `beep` take their durations in ticks.
2. If the byte before `last_rip` is `0xF4` (the opcode of `hlt`), `idle_ticks++`. After a `hlt` is interrupted, the saved `rip` points past the instruction, so `rip - 1` is the `hlt` itself. Every `hlt` in the kernel is a halt-and-wait, so this counts the ticks that arrived while the CPU was halted. The `idle` word returns `idle_count()`. The comparison `idle / ticks` is the idle share.
3. If `tick_count % HZ == 0`, calls `draw_tabbar`, which redraws the tab bar and the clock once per second.

`last_rip` is written for every IRQ before its handler runs. `irq_count(n)` returns `irqn[n]`, and the `irq` word exposes it for `n` from 0 to 15.

`beep` programs PIT channel 2 (ports `0x43` with `0xB6`, and `0x42`) and gates the speaker with bits 0 and 1 of port `0x61`. It waits with the same yield loop as `sleep`.

### Exceptions

The 32 exception names are in `exc[32]`: divide by zero, debug, nmi, breakpoint, overflow, bound range, invalid opcode, no fpu, double fault, coprocessor overrun, bad tss, segment not present, stack fault, general protection fault, page fault, reserved, fpu error, alignment check, machine check, simd error, virtualization, control protection, then reserved entries, hypervisor injection, vmm communication, security, and a last reserved entry.

Every exception goes through `task_fault`. If `current->id < 0`, meaning the fault happened while `current` was `idle_task` (during early boot before the first tick, or in the `hlt` loop), `task_fault` calls `panic`. Otherwise the running tab is restarted. See the section on panics and faults.

Nothing handles double faults separately. A double fault is vector 8 and takes the same path. Since there is no IST, a fault caused by a bad stack pointer cannot be delivered to a good stack and ends in a triple fault and a machine reset.

### Reading CPU information

`cpu_brand` in `kernel/cpu.c` uses CPUID leaves `0x80000002` to `0x80000004` for the brand string when leaf `0x80000000` reports them, and falls back to the 12-byte vendor string from leaf 0 (registers ordered `ebx, edx, ecx`). Leading spaces are skipped. It is used by `sysinfo`.

## Tasks and the scheduler

See [scheduler](scheduler.md), [tabs](tabs.md) and [idle](idle.md) for the user view.

### `struct task`

`struct task` in `kernel/task.h` is the only per-task structure. There are exactly `NTABS` (4) tasks, in the static array `tabs[NTABS]`, plus `idle_task`, which is static in `kernel/sched.c`.

| Field | Type | Meaning |
|---|---|---|
| `rsp` | `u64` | Saved stack pointer. Points at a `struct regs` frame when the task is not running. |
| `id` | `int` | Index into `tabs`, 0 to 3. `-1` for the idle task. |
| `entry` | `void (*)(void)` | Where the task starts, `omega_main` for the shells. A task with `entry == NULL` is never runnable. |
| `stack` | `u8 *` | Base of the `KSTACK` (256 KiB) block, allocated once and kept across restarts. |
| `wait_key` | `int` | Nonzero while blocked in `kbd_get` or `waitkey`. |
| `mouse_on` | `int` | Nonzero while a program wants mouse events, set by the pager. |
| `wake_at` | `u64` | Tick at which a sleeping task becomes runnable. 0 means no timer. |
| `kb[64]`, `kh`, `kt` | `volatile int` | Key ring: storage, head (written by the IRQ), tail (written by the consumer). |
| `brkflag` | `volatile int` | Set by Ctrl-C in `on_key`. Read as `kbreak`, a macro for `current->brkflag`. |
| `term` | `struct term` | The tab's text buffer, write position and cursor. |
| `title[24]` | `char` | Tab title, shown in the tab bar. |
| `fault[96]` | `char` | Message left by `task_fault`, printed once by `omega_main`. |
| `om` | `struct omega *` | The shell state. `W` is a macro for `current->om`. |
| `ed`, `calc` | pointers | State of the editor and the calculator for this tab. |

`struct term`:

| Field | Meaning |
|---|---|
| `buf[VW * VH]` | 80 by 24 cells. Each `u16` is the character in the low byte and the attribute in the high byte. |
| `cx`, `cy` | Where the next `kputc` writes |
| `curx`, `cury` | Where the hardware cursor was last set, in buffer coordinates |
| `activity` | Set when a non-active tab writes, shown as `*` after the title |
| `attr` | Current attribute for `kputc` |

Because `kb`, `term` and the pointers sit in the static `tabs[]`, they are in `.bss` and are zero until `sched_init` initialises `term`, `id` and `title`.

### Constants

| Name | Value | File |
|---|---|---|
| `NTABS` | 4 | `kernel/task.h` |
| `KSTACK` | `256 * 1024` | `kernel/sched.c` |
| `HZ` | 100 | `kernel/cpu.h` |
| key ring size | 64 entries | `kernel/kbd.c`, `kernel/task.h` |

### `frame_for` and `task_start`

`frame_for(t)` builds the initial interrupt frame at the top of the task's stack:

    u64 top = ((u64)t->stack + KSTACK) & ~15ull;
    struct regs *r = (struct regs *)(top - 16 - sizeof(struct regs));

It zeroes the frame and sets `rip = t->entry`, `cs = 0x08`, `rflags = 0x202` (`IF` set and the reserved always-1 bit), `rsp = top - 8` and `ss = 0x10`. The `top - 8` leaves the stack in the state it would have after a `call`, so the entry function sees the alignment the System V ABI expects. All general registers are zero. The first time the scheduler returns this frame, `iretq` starts the task with interrupts on.

`task_start(t, entry)` stores `entry`, allocates the stack with `kmalloc(KSTACK)` only if `t->stack` is null, and sets `t->rsp = frame_for(t)`.

### `schedule`

    u64 schedule(struct regs *r) {
        current->rsp = (u64)r;
        int start = current->id < 0 ? NTABS - 1 : current->id;
        for (int k = 1; k <= NTABS; k++) {
            struct task *t = &tabs[(start + k) % NTABS];
            if (runnable(t)) { current = t; return t->rsp; }
        }
        current = &idle_task;
        return idle_task.rsp;
    }

It saves the frame pointer of whoever was interrupted, scans the tabs round-robin starting after the current one, and returns the saved frame of the first runnable tab. The scan includes the current tab as the last candidate, so a lone runnable tab keeps running. If no tab is runnable the idle task is chosen. There are no priorities and no time-slice counters. A runnable task runs until the next timer tick or until it yields.

When `current` is the idle task the scan starts at tab 0. `idle_task.rsp` is whatever frame was last stored for it, which is a frame inside the `hlt` loop of `kmain`. The idle task has no entry point and no stack of its own. It is the code that was running when the system booted, on `boot_stack`.

### Runnable rules

    static int runnable(struct task *t) {
        if (!t->entry) return 0;
        if (!t->wait_key && !t->wake_at) return 1;
        if (t->wait_key && t->kh != t->kt) return 1;
        if (t->wake_at && ticks() >= t->wake_at) return 1;
        return 0;
    }

| `wait_key` | `wake_at` | Runnable when |
|---|---|---|
| 0 | 0 | always |
| 1 | 0 | the key ring is not empty |
| 0 | nonzero | `ticks() >= wake_at` |
| 1 | nonzero | the ring is not empty or the time has come |

The fourth row is `waitkey` with a timeout in `kernel/hw.c`: it sets both fields, polls `kbd_poll`, and yields until a key arrives or `ticks()` reaches `wake_at`. A blocked task is not removed from anything. The scheduler re-evaluates these conditions on every pass. A task blocks by setting a field and calling `yield`, and it must clear the field when it resumes, as `kbd_get`, `sleep_until`, `b_sleep`, `b_beep` and `b_waitkey` do. A task that leaves `wake_at` set to a tick that has passed stays runnable and keeps running.

### `yield` and `sleep_until`

`yield()` is `int $48` on the kernel and `host_yield()` in the host build, which advances the fake clock by one tick. After `int $48` the CPU pushes a frame and enters `isr48`. `schedule` stores it and picks the next task, possibly the same one. Code that waits in a loop should block through `wait_key` or `wake_at` rather than spin on `yield`, because a spinning task still counts as runnable and the idle task never runs.

`sleep_until(tick)` sets `wake_at`, calls `yield` until `ticks() >= tick`, and clears `wake_at`. The `sleep` word in `hw.c` does the same loop with an extra `!kbreak` condition, so Ctrl-C ends it, and calls `brk()` afterwards to report `interrupted`.

### The idle task

`idle_task` is a `struct task` with `id = -1` and no `entry`. When `schedule` finds no runnable tab it returns `idle_task.rsp`, which resumes the `for (;;) hlt` loop of `kmain` with interrupts on. `hlt` waits for the next interrupt. If it is the timer, `schedule` runs again and rescans. If it is a key, `on_key` fills the ring and the following tick finds the tab runnable. Idle accounting (the byte before `last_rip` being `0xF4`) is based on this.

The idle task must never block or be faulted. A fault while `current == &idle_task` is a panic.

### Faults

`task_fault(r, msg)` is the exception path of every tab.

    u64 task_fault(struct regs *r, const char *msg) {
        if (current->id < 0) panic(msg);
        scopy(current->fault, msg, sizeof current->fault);
        current->wait_key = 0;
        current->wake_at = 0;
        current->rsp = frame_for(current);
        return current->rsp;
    }

The faulting frame `r` is discarded. The tab's stack is reused: `frame_for` writes a new initial frame at the top of the same block, so the task restarts at `omega_main` with an empty call stack. Heap objects allocated by the interrupted code are not freed by this path. The shell's garbage collector reclaims what is reachable only through its own roots, and memory allocated with plain `kmalloc` by the faulted code stays allocated. State that `task_fault` does not reset: the key ring (`kb`, `kh`, `kt`), `brkflag`, `mouse_on`, `term` and `om`.

### `irq_save` and `irq_restore`

    static inline u64 irq_save(void)   { u64 f; __asm__ volatile("pushfq; pop %0; cli" : "=r"(f) : : "memory"); return f; }
    static inline void irq_restore(u64 f) { __asm__ volatile("push %0; popfq" : : "r"(f) : "memory", "cc"); }

`irq_save` returns the old `rflags` and disables interrupts. `irq_restore` puts back that value, which re-enables interrupts only if they were enabled before. This makes the pair nestable and safe to call with interrupts already off, such as from a handler. Both carry a `memory` clobber so the compiler does not move accesses across them. In the host build (`-DHOST`) they are empty functions.

Interrupts are off in an interrupt handler and on in tab code, so the rule is about which data is touched from both contexts, or from two tabs that can preempt each other.

| Data | Written from | Protection |
|---|---|---|
| heap list and counters | any task | `irq_save` in `kmalloc_try`, `kfree` |
| `tabs[].term.buf` and the screen | task (`vga_put`, `scroll`, `vga_cursor`), IRQ (`switch_tab`, `mouse_move`, `draw_tabbar`) | `irq_save` in each of those functions |
| key ring | IRQ (head), task (tail) | no lock, one producer and one consumer, `volatile` indexes |
| mouse event ring | IRQ (head), task (tail) | `mouse_event` and `mouse_flush` take `irq_save` |
| ATA registers | any task | `irq_save` around each chunk of up to 128 sectors in `disk_rw` |
| `hdr` in `persist.c` | tasks | the header is copied under `irq_save` and the copy is written |
| `tick_count`, `idle_ticks`, `irqn` | IRQ | `volatile`, read without a lock |

Per-task data in a tab's own `struct task` and `struct omega` needs no protection from other tabs. Only code that touches another tab's fields or the shared hardware needs it.

An interrupt-off section delays the timer. Long sections accumulate lost ticks, because the PIT counter reloads on its own and a missed IRQ 0 is not replayed. `disk_rw` is the longest one in the kernel: a 128-sector chunk is 64 KiB of programmed I/O with interrupts off.

## The screen

See [screen](screen.md) and [themes](themes.md) for the user view. The code is `kernel/vga.c`, `kernel/vga.h`, `kernel/font.c` and the graphics part of `kernel/hw.c`.

### Geometry

| Constant | Value |
|---|---|
| `VW` | 80 |
| `VH` | 24 |
| Hardware text rows | 25 |

The hardware text buffer at `0xB8000` has 80 by 25 cells. Row 0 is the tab bar. Rows 1 to 24 show the active tab's 24-row buffer. A cell is a `u16`: the character in the low byte, the attribute in the high byte, foreground in the low nibble and background in the high nibble. `ATTR(fg, bg)` builds it.

Code uses the tab buffer's coordinates (y from 0 to 23). The conversion to hardware coordinates (y + 1) is made inside `vga_put`, `vga_cursor`, `scroll`, `switch_tab` and the mouse code. Only `hw_put` and `mouse_*` take hardware coordinates.

### Colours

The 16 colour names are an enum in `vga.h`:

| Value | Name | Value | Name |
|---|---|---|---|
| 0 | `C_BG` | 8 | `C_DIM` |
| 1 | `C_BAR` | 9 | `C_BLUE` |
| 2 | `C_GREEN` | 10 | `C_LGREEN` |
| 3 | `C_TEAL` | 11 | `C_SKY` |
| 4 | `C_RED` | 12 | `C_LRED` |
| 5 | `C_MAUVE` | 13 | `C_PINK` |
| 6 | `C_PEACH` | 14 | `C_MOON` |
| 7 | `C_TEXT` | 15 | `C_CAT` |

A theme is a `struct theme { const char *name; u32 rgb[16]; }`, and `themes[]` in `vga.c` is terminated by an entry with a `NULL` name. The themes are `dusk` (index 0, the default), `raw`, `paper`, `amber`, `phosphor` and `haelide`. `raw` carries the standard VGA colours. Adding a theme means adding an entry before the terminator. `vga_theme(n)` counts the entries, returns -1 for an out-of-range `n`, stores `cur_theme` and programs all 16 colours.

### DAC mapping

In text mode the attribute controller maps the 4-bit colour in an attribute to a DAC index through its palette registers. The BIOS default palette is not linear, so `vga_rgb` converts through `dac_index`:

    static u8 dac_index(int i) { return i < 6 ? (u8)i : i == 6 ? 0x14 : i == 7 ? 7 : (u8)(0x38 + i - 8); }

| Colour index | DAC index |
|---|---|
| 0 to 5 | 0 to 5 |
| 6 | `0x14` |
| 7 | 7 |
| 8 to 15 | `0x38` to `0x3F` |

`vga_rgb(i, rgb)` writes the DAC index to port `0x3C8`, then the red, green and blue components to `0x3C9`, each reduced to six bits (`>> 18`, `>> 10`, `>> 2` with a `0x3F` mask). A new theme that needs more than 16 colours cannot be done in text mode. In graphics mode the DAC is linear and `b_gfx` writes index `i` directly.

### `hw_put` and `vga_put`

`hw_put(x, y, c, a)` writes one cell of the hardware buffer if `!gfx_on` and `0 <= x < VW` and `0 <= y <= VH` (rows 0 to 24). It does not touch any tab buffer. It is for the tab bar, the panic screen and the pointer.

`vga_put(x, y, c, a)` is the normal write for tab content. It ignores coordinates outside 80 by 24. Under `irq_save` it:

1. stores the cell in `current->term.buf[y * VW + x]`,
2. if `current` is not the active tab, sets `activity` so the tab bar shows `*`,
3. if `current` is the active tab and graphics mode is off, writes `HW[(y + 1) * VW + x]`, and if the pointer is on that cell, calls `mouse_redraw()` to restore the inversion.

The buffer is always updated. The screen is updated only for the active tab. This is why a background tab can keep printing: its output goes to `term.buf`, and `switch_tab` copies the whole buffer to the hardware.

`vga_puts_at` and `vga_fill` loop over `vga_put`. `vga_clear` fills the 24 rows with spaces in `ATTR(C_TEXT, C_BG)`, resets `cx` and `cy`, and moves the cursor to 0, 0.

### `kputc`, scrolling and the cursor

`kputc` is the console output of a tab. It handles `\n` (column 0, next row), `\r`, `\t` (spaces to the next multiple of 4), `\b` (one column left, no erase) and printable characters. After a character at column 79 the position wraps to column 0 of the next row. When `cy` reaches `VH`, `scroll` is called.

`scroll` moves rows 1 to 23 up by one in `term.buf` with `memmove`, fills the last row with spaces in `ATTR(C_TEXT, C_BG)`, and sets `cy = VH - 1`. If the tab is active and graphics mode is off, it then copies the whole buffer into rows 1 to 24 of the hardware buffer and calls `mouse_redraw`. Scrolling redraws 24 rows, it does not use the VGA start-address register. It runs under `irq_save` for the buffer and the screen copy.

`vga_cursor(x, y)` stores `curx`, `cury` and moves the hardware cursor to row `y + 1` if the tab is active. `hw_cursor` writes the linear position `y * 80 + x` to CRTC registers `0x0F` (low) and `0x0E` (high) through ports `0x3D4` and `0x3D5`. `b_nocursor` hides the cursor by placing it at row `VH`, which is hardware row 25, below the visible area.

`vga_color(fg)` sets the tab's attribute to `ATTR(fg, C_BG)`. `vga_attr(a)` sets it directly.

### Bright backgrounds and the cursor shape

`vga_init` clears bit 3 of the attribute controller mode register (index `0x10`, written through port `0x3C0` after reading `0x3DA` to reset the flip-flop, with the `0x20` palette-address-source bit held in the index byte `0x30`). With blink disabled, attribute bit 7 selects one of 16 background colours. The active tab label uses `C_MOON` (14) as its background. The CRTC cursor start and end registers (`0x0A`, `0x0B`) are set to 0 and 15, a full-height block cursor.

### Fonts: codes 0x80 to 0x8B

`font_init` in `kernel/font.c` redefines twelve glyphs. Each is 16 bytes, one byte per scan line, bit 7 on the left.

| Code | Glyph |
|---|---|
| `0x80` | omega |
| `0x81` | aleph |
| `0x82` to `0x8B` | subscript digits 0 to 9 |

Font memory is plane 2 of VGA memory, with 32 bytes reserved per character. Glyph `g` is written to `0xA0000 + (0x80 + g) * 32 + row`. To reach plane 2, `plane2_open` sets sequencer register `0x02` to `0x04` (map mask: plane 2 only), `0x04` to `0x07` (sequential addressing), graphics controller `0x04` to `0x02` (read plane 2), `0x05` to `0x00` and `0x06` to `0x04` (map `0xA0000`, 64 KiB). `plane2_close` restores the text-mode values: sequencer `0x02` = `0x03`, `0x04` = `0x03`, graphics controller `0x04` = `0x00`, `0x05` = `0x10`, `0x06` = `0x0E`.

`font_save(buf)` and `font_restore(buf)` copy `FONT_BYTES` (8192 = 256 * 32) bytes between font memory and a buffer. `glyph()` in `hw.c` draws graphics-mode text from the saved copy. Because `font_init` runs before the tabs exist and nothing else reopens plane 2 in text mode, the only other writer is the graphics mode switch. These characters can be written from omega with `put` and `text` by using their codes.

### The tab bar

`draw_tabbar` writes row 0 with `hw_put`, under `irq_save`. It fills the row with spaces in `ATTR(C_DIM, C_BAR)`, then for each tab writes the text from `tab_text`, which is the string `" N title* "` where `*` is present only for an inactive tab with `activity` set. The active tab is drawn in `ATTR(C_BG, C_MOON)`, the others in the bar attribute. One blank cell separates the labels, and the first label starts at column 1. The clock is `HH:MM` at columns `VW - 6` to `VW - 2`, read from the CMOS RTC (register 4 hours, 2 minutes, `0x0B` status B, bit 2 = binary mode) and converted from BCD when the RTC is in BCD mode. The function ends with `mouse_redraw()` if the pointer is on row 0.

`tab_at(x)` returns the tab whose label covers column `x`, or -1. It recomputes the same layout as `draw_tabbar` using `tab_text`, so the two stay in step as long as the label format is changed in one place.

`draw_tabbar` is called from `on_tick` once per second, from `set_title`, from `switch_tab`, and from `mouse_move` when it restores row 0.

### `switch_tab`

`switch_tab(n)` ignores values outside 0 to 3. Otherwise it calls `gfx_leave()` first, so a tab switch always leaves graphics mode. Under `irq_save` it sets `active_tab`, clears the tab's `activity`, copies the tab's buffer to hardware rows 1 to 24, moves the cursor to the tab's `curx`, `cury + 1`, calls `draw_tabbar`, and then `mouse_redraw`. It is called from `on_key` (F1 to F4, Alt+1 to 4), from `on_mouse` (click on the bar), from `kmain` for tab 0, and from `b_gfxoff` to repaint after leaving graphics mode.

### Graphics mode

The `gfx` word switches the display to 640 by 480 with 8 bits per pixel through the Bochs VBE interface, which QEMU provides with `-vga std`. See [qemu](qemu.md) for the command line and [hardware](hardware.md) for why it needs that device. All of it is in `kernel/hw.c`.

`find_lfb` scans PCI bus 0, devices 0 to 31, function 0, for the identification dword `0x11111234` (vendor `0x1234`, device `0x1111`) and returns BAR 0 with the low four bits cleared. `b_gfx` then:

1. returns at once if `gfx_on` is set,
2. writes index 0 to port `0x1CE` and reads `0x1CF`, which must be `0xB0C0` in the top 12 bits (the DISPI ID register), and fails with a message if no device was found, the BAR is at or above 4 GiB, or the ID is wrong,
3. stores the framebuffer address in `lfb`,
4. calls `vga_save()` and `font_save(saved_font)`,
5. sets `gfx_on = 1`,
6. sets the DISPI registers through `vbe(index, value)`, which writes the index to `0x1CE` and the value to `0x1CF`: disable (index 4, value 0), X resolution (index 1, `GW` = 640), Y resolution (index 2, `GH` = 480), bits per pixel (index 3, 8), then enable (index 4, value `0x41`, enable plus linear framebuffer),
7. loads the current theme's 16 colours into DAC entries 0 to 15 directly.

The framebuffer is `GW * GH` bytes, one byte per pixel, index = colour 0 to 15. `dot`, `box` and `window` write to it, `text` calls `gtext` when `gfx_on` is set, and all fail with `graphics mode is off, run gfx first` otherwise.

`gfx_on` is global. It is not per tab. While it is set:

- `hw_put` writes nothing, `vga_put` and `scroll` update only the tab buffers, `mouse_redraw` does nothing, and `draw_tabbar` writes nothing visible. Output from all tabs is kept in the buffers.
- The hardware text buffer is not displayed.

`gfx_leave` undoes the mode: it returns if `gfx_on` is clear, then `vbe(4, 0)` to disable VBE, `font_restore(saved_font)`, `vga_restore()`, `vga_theme(vga_current_theme())` to reprogram the DAC, and `gfx_on = 0`. `b_gfxoff` calls `gfx_leave` and then `switch_tab(active_tab)` to repaint the text screen. `switch_tab` itself also calls `gfx_leave`, which is how F1 to F4 and the mouse leave graphics mode from interrupt context.

### Saving and restoring VGA registers

Switching VBE on reprograms the VGA register file and the font plane, so both are saved first. `vga_save` stores into the static struct `rs`:

| Group | Registers | Index port / data port |
|---|---|---|
| Miscellaneous output | 1 (read from `0x3CC`) | |
| Sequencer | 5 | `0x3C4` / `0x3C5` |
| CRTC | 25 | `0x3D4` / `0x3D5` |
| Graphics controller | 9 | `0x3CE` / `0x3CF` |
| Attribute controller | 21 | `0x3C0` / `0x3C1` |

For the attribute controller each read first reads `0x3DA` to reset the address/data flip-flop and writes the index with bit 5 (`0x20`) set so the display stays on. `vga_restore` writes them back in a safe order: miscellaneous output to `0x3C2`, sequencer reset (register 0 = 1), sequencer registers 1 to 4, sequencer run (register 0 = 3), CRTC register `0x11` with its write-protect bit (bit 7) cleared so registers 0 to 7 are writable, CRTC registers in order except `0x11`, then `0x11` with its saved value, graphics controller, attribute controller (index without bit 5, so the display is blanked while the palette registers are written), and finally `0x20` to the attribute index to turn the display on.

The font is restored before the registers because the VBE mode scribbles on plane 2.

## The keyboard

See [keyboard](keyboard.md), [keys](keys.md), [scancodes](scancodes.md) and [ps2](ps2.md). The code is `kernel/kbd.c` and `kernel/kbd.h`.

### Scancodes and translation

`on_key` runs on IRQ 1. It reads one byte from port `0x60`. The controller delivers scancode set 1, one byte per make or break code. Bit 7 of the byte marks a release.

| Byte | Handling |
|---|---|
| `0xE0` | Sets `ext = 1` and returns. The flag applies to the next byte only. |
| `0x2A`, `0x36` | Left and right shift: `shift = !up` |
| `0x1D` | Control: `ctrl = !up` |
| `0x38` | Alt: `alt = !up` |
| any release | Ignored after the modifier check |
| `0x3A` | Caps lock, toggles `caps` on press |
| `0x3B` to `0x3E` | F1 to F4: `switch_tab(sc - 0x3B)` |
| `0x02` to `0x05` with `alt` | Alt+1 to Alt+4: `switch_tab(sc - 0x02)` |
| `0x48`, `0x50`, `0x4B`, `0x4D` | `K_UP`, `K_DOWN`, `K_LEFT`, `K_RIGHT` |
| `0x47`, `0x4F` | `K_HOME`, `K_END` |
| `0x49`, `0x51` | `K_PGUP`, `K_PGDN` |
| `0x53` | `K_DEL` |
| `0x0F` with shift | `K_BTAB` |

The `ext` flag is read into a local `e` and cleared before the switch. It is used for one thing: `e && sc == 0x1C` pushes newline for the keypad Enter. The arrow and editing keys are matched by scancode alone, so the numeric keypad's keys produce the same codes as the dedicated keys. Right Control and Right Alt send the same scancode with an `0xE0` prefix and set the same state flags.

Other scancodes go through two 58-character tables, `normal` and `shifted`, indexed by scancode (0 to 57). A zero entry means no character, which covers the modifier positions. A scancode of 58 or above is dropped. The tables are for a US layout.

After the table lookup:

1. With `caps` set, a letter has its case inverted: `a` to `z` becomes upper case and `A` to `Z` becomes lower case. With shift also held, the shifted table gives upper case and caps turns it to lower case.
2. If `ctrl` is held and the character is `c` or `C`, `tabs[active_tab].brkflag` is set to 1.
3. If `ctrl` is held and the character is a letter, it is replaced by `CTRL(c)`, which is `c & 0x1F`. Control with a non-letter gives the plain character.
4. The result is pushed as an `int`.

So Ctrl-C both sets `brkflag` of the active tab and pushes `0x03` into the same tab's ring. Long-running code polls `kbreak` (via `brk()`) to stop. The line editor consumes the `0x03` and prints `^C`. `eval_line` clears `kbreak` at the start of every line, and `brk()` clears it when it reports `interrupted`.

### The codes in `kbd.h`

Keys that are not characters are numbered from `0x100`, above any `u8`:

| Name | Value |
|---|---|
| `K_UP` | `0x100` |
| `K_DOWN` | `0x101` |
| `K_LEFT` | `0x102` |
| `K_RIGHT` | `0x103` |
| `K_HOME` | `0x104` |
| `K_END` | `0x105` |
| `K_PGUP` | `0x106` |
| `K_PGDN` | `0x107` |
| `K_DEL` | `0x108` |
| `K_MOUSE` | `0x109` |
| `K_BTAB` | `0x10A` |
| `K_ESC` | 27 (`#define`) |

Printable characters are their ASCII values. Backspace is 8, Tab 9, Enter 10 (`\n`). `K_MOUSE` is not a key. It is injected by `on_mouse` so a program that blocks in `kbd_get` wakes for mouse events. Programs that do not enable the mouse never see it.

### The ring

Each task has `volatile int kb[64]` with head `kh` and tail `kt`. `push(k)` in `kbd.c` always targets `tabs[active_tab]`: input goes to the tab that is on the screen, whichever task is running. It stores at `kh` and advances `kh` modulo 64 unless that would equal `kt`. A full ring drops the new key, and one slot is always unused, so the capacity is 63 keys.

The producer is `on_key` (and `post` in `mouse.c`) in interrupt context, the consumer is the owning task. Each index is written by one side only, which is why no lock is used.

### Reading keys

`kbd_poll()` returns the next key of `current`, or -1 if the ring is empty. `kbd_get()` loops on `kbd_poll`. While the ring is empty it sets `current->wait_key = 1` and calls `yield()`; once a key arrives it clears `wait_key` and returns. A key that arrives between the empty poll and the `wait_key = 1` store is not lost: `runnable` sees `kh != kt` at the next scheduling pass.

`kbd_init` drains the controller output buffer (`while (inb(0x64) & 1) inb(0x60);`) and installs `on_key` for IRQ 1. The keyboard's LEDs and typematic settings are not changed.

The `key` word returns `kbd_get()`, `key?` returns `kbd_poll()` (-1 for none), and `waitkey` takes a timeout in ticks and returns -1 on timeout.

### Tab switching keys

F1 to F4 and Alt+1 to Alt+4 call `switch_tab` from interrupt context. They are handled before the character tables, so they never reach the ring. The switch does not depend on which task is running.

In the host build there is no `kbd.c`. `test/host.c` supplies `kbd_poll`, `kbd_get` and `kbd_init`, and the directive that feeds keys writes directly into `current`'s ring. Changes to `on_key`, to the tables, or to the shift state machine are not exercised by `make host` and have to be tested in QEMU.

## The mouse

See [mouse](mouse.md) and [ps2](ps2.md). The code is `kernel/mouse.c` and the pointer drawing is in `kernel/vga.c`. The initialisation and the IRQ handler are compiled out of the host build (`#ifndef HOST`).

### Controller initialisation

`mouse_init` talks to the 8042 controller through port `0x64` (status and command) and port `0x60` (data). `wait_in` polls up to 100000 times for the input buffer to be empty (status bit 1 clear). `wait_out` polls up to 100000 times for output data (status bit 0 set). Any timeout makes `mouse_init` return, leaving `mouse_found` at 0 and no handler installed.

| Step | Action |
|---|---|
| 1 | Command `0xA8`: enable the auxiliary port |
| 2 | Command `0x20`: read the controller command byte |
| 3 | Set bit 1 (enable IRQ 12) and clear bit 5 (enable the auxiliary clock) |
| 4 | Command `0x60`, then write the modified byte |
| 5 | `write_mouse(0xF6)`: set defaults. A reply other than `0xFA` aborts. |
| 6 | Set sample rate to 200, 100, then 80 (`0xF3` followed by the rate each time) |
| 7 | `write_mouse(0xF2)`: get device ID. A following byte of 3 means a wheel mouse, `wheel = 1`. |
| 8 | `write_mouse(0xF4)`: enable streaming. A reply other than `0xFA` aborts. |
| 9 | `irq_set(12, on_mouse)` and `mouse_found = 1` |

`write_mouse(v)` sends command `0xD4` (next byte goes to the auxiliary device), writes `v` to port `0x60`, waits for output and returns the byte read. The sample rate sequence 200, 100, 80 is the standard way to switch an IntelliMouse-compatible device to the 4-byte protocol. The `mouse?` word returns `mouse_found`.

### Packets

`on_mouse` reads one byte per IRQ 12. If `np == 0` and bit 3 of the byte is clear, the byte is discarded: the first byte of a packet always has bit 3 set, which resynchronises after a lost byte. Bytes are collected in `pk[]` until `np` reaches 3, or 4 when `wheel` is set.

| Byte | Content |
|---|---|
| `pk[0]` | Bit 0 left button, bit 1 right, bit 2 middle, bit 3 always 1, bit 4 X sign, bit 5 Y sign |
| `pk[1]` | X movement, low 8 bits |
| `pk[2]` | Y movement, low 8 bits |
| `pk[3]` | With a wheel: low 4 bits are the wheel movement, 2's complement |

`dx = pk[1]`, minus 256 if bit 4 of `pk[0]` is set. `dy` likewise with bit 5. The wheel value is `pk[3] & 15`, minus 16 if bit 3 of it is set. Overflow bits (6 and 7) are not examined. `btn = pk[0] & 7`, and `down = btn & ~old` is the set of buttons that went down in this packet.

### Pixel to cell scaling

The pointer position is kept in a virtual pixel grid of `PW` by `PH`:

    #define PW (VW * 8)         /* 640 */
    #define PH ((VH + 1) * 16)  /* 400 */

`px` starts at `PW / 2` and `py` at `PH / 2`. Each packet adds `dx` to `px` and subtracts `dy` from `py` (PS/2 Y grows upward), clamped to `0 .. PW - 1` and `0 .. PH - 1`. The cell is `px / 8` and `py / 16`, which gives 80 columns and 25 rows. Row 0 is the tab bar, so a cell row of `n` is tab buffer row `n - 1`. One count of mouse movement is one pixel in this grid, and eight counts move the pointer one column.

The cell is passed to `mouse_move(cx, cy)` on every packet. The global `mouse_cx`, `mouse_cy` and `mouse_shown` hold the pointer cell and whether it has been drawn. The pointer is not drawn until the first packet arrives.

### Clicks and events

After `mouse_move`, `on_mouse` handles two cases.

1. A left button press on row 0 over a tab label (`tab_at(mouse_cx) >= 0`) calls `switch_tab` and returns. This works whether or not `mouse_on` is set.
2. Otherwise, if any button went down or the wheel moved, `post(mouse_cx, mouse_cy - 1, down, dz)` is called. The y passed is in tab buffer coordinates.

`post` does nothing unless the active tab has `mouse_on` set. It appends a `struct mev { int x, y, down, dz; }` to a single ring `ev[16]` shared by all tabs (`NEV` is 16), with head `eh` and tail `et`. The ring is full when `(eh + 1) % NEV == et`, which holds 15 events. In that case the new event is dropped, and the oldest stay. Independently, `post` appends `K_MOUSE` to the active tab's key ring unless that ring is full. The key and event rings can therefore differ in count. A consumer reads events with `while (mouse_event(&e))` after receiving `K_MOUSE`.

`mouse_event` takes one event under `irq_save` and returns 0 when the ring is empty. `mouse_flush` sets `et = eh` under `irq_save` and is called when a program starts listening so that old events do not appear.

The `mouse` word pushes `mouse_cx`, `mouse_cy - 1` and the current button state `btn` (not only new presses).

### Drawing the pointer

The pointer is the hardware cell under it with foreground and background swapped, and no separate sprite. In `kernel/vga.c`:

    static void swap_cell(int x, int y) {
        u16 v = HW[y * VW + x], a = v >> 8;
        HW[y * VW + x] = (u16)((v & 0xFF) | (u16)(((a << 4) | (a >> 4)) & 0xFF) << 8);
    }

`mouse_redraw` calls `swap_cell(mouse_cx, mouse_cy)` if `mouse_shown && !gfx_on`. Because the swap is its own inverse, the screen holds either the true cell or its inversion, and every code path that rewrites a cell the pointer sits on has to either restore the true value first or invert again afterwards. The places where `mouse_redraw` is called are:

| Where | Why |
|---|---|
| `vga_put` | After writing a cell on the pointer position, to invert the new content |
| `scroll` | After the hardware buffer was overwritten with the new rows |
| `draw_tabbar` | After row 0 was rewritten, when `mouse_cy == 0` |
| `switch_tab` | After the new buffer and the bar were copied to the screen |
| `mouse_move` | After the pointer is placed in its new cell |

`mouse_move(x, y)` runs under `irq_save`. If a pointer is currently drawn, it clears `mouse_shown` temporarily, restores the old cell, then sets the new position and `mouse_shown = 1` and inverts the new cell. The old cell on rows 1 to 24 is restored from the active tab's buffer, `tabs[active_tab].term.buf[(oy - 1) * VW + ox]`, not from the screen. For row 0 the old cell is restored by calling `draw_tabbar()`, which redraws the whole row. Clearing `mouse_shown` before these calls stops `draw_tabbar` from inverting the cell a second time.

Note for changes here: `switch_tab` calls `draw_tabbar` and then `mouse_redraw`. When the pointer is on row 0, `draw_tabbar` has already inverted the cell, so the second call inverts it back and the pointer is not visible until the next mouse movement or the next once-a-second tab bar redraw.

The pointer is hidden in graphics mode, since all of the above is skipped when `gfx_on` is set.

### The pager

The only reader of mouse events is the help pager, `open_page` in `kernel/doc.c`. On entry it sets `current->mouse_on = 1` and calls `mouse_flush()`. On exit it sets `mouse_on = 0`. It never calls `mouse_redraw`, because its drawing goes through `vga_put`, which maintains the pointer by itself.

The pager waits in `kbd_get`. On `K_MOUSE` it drains events:

- `dz` scrolls by `dz * 3` lines,
- the right button (`down & 2`) goes back in the page history,
- the left button (`down & 1`) on a text row inside the page (`1 <= y <= VIEW`) looks up `L[top + y - 1].lk[x]`, the link id stored for that cell, and follows the link if it is nonzero.

A new program that uses the mouse follows the same pattern: set `mouse_on`, call `mouse_flush`, block in `kbd_get`, drain `mouse_event` on `K_MOUSE`, and clear `mouse_on` before returning. The flag stays set if the task is restarted by `task_fault`.

## Disks and persistence

See [disk-layout](disk-layout.md), [saving](saving.md), [drives](drives.md) and [installation](installation.md) for the user view. The kernel side is `kernel/disk.c`, `kernel/disk.h` and `kernel/persist.c`. The boot side is `boot/mbr.asm` and `boot/stage2.asm`.

### ATA probing

`disk_init` fills `drives[4]`:

| Index | Channel | Position | I/O base | Control port |
|---|---|---|---|---|
| 0 | primary | master | `0x1F0` | `0x3F6` |
| 1 | primary | slave | `0x1F0` | `0x3F6` |
| 2 | secondary | master | `0x170` | `0x376` |
| 3 | secondary | slave | `0x170` | `0x376` |

For each position it reads the status register (`io + 7`); a value of `0xFF` means no controller and the entry stays empty. Otherwise `identify` runs:

1. `outb(ctl, 0x02)` sets `nIEN` so the device does not raise interrupts.
2. Select the device with `0xA0 | slave << 4` in `io + 6`, then four reads of the control port as a 400 ns delay.
3. Zero the sector count and LBA low, mid and high registers.
4. Send `IDENTIFY` (`0xEC`). A status of 0 means no device.
5. Wait up to 1000000 reads for BSY to clear. A non-zero LBA mid or high means an ATAPI or other non-ATA device, and the position is skipped.
6. `wait(d, 1)` for DRQ, then read 256 words.

From the identify data the model string is taken from words 27 to 46 (the bytes of each word are swapped, trailing spaces are trimmed), `lba48` from word 83 bit 10, and `sectors` from words 100 to 103 if `lba48` else words 60 and 61. A drive is `present` if `sectors > 0`. `struct drive` holds `present`, `slave`, `lba48`, `io`, `ctl`, `sectors` and `model[41]`.

`wait(d, drq)` polls the status register up to 2000000 times. A set BSY bit (`0x80`) continues. A set ERR (`0x01`) or DF (`0x20`) returns -1. With `drq` set it returns 0 only when DRQ (`0x08`) is set. A timeout returns -1.

### `disk_rw`

    int disk_rw(int n, u64 lba, u32 count, void *buf, int write)

It returns 0 on success and -1 on a bad drive number, a drive that is not present, a transfer that would pass `drives[n].sectors`, or any device error. It transfers in chunks of at most 128 sectors. For each chunk, under `irq_save`:

1. wait for BSY to clear,
2. program the registers: for LBA48 the drive select `0x40 | slave << 4`, the sector count and LBA bytes in two writes (high bytes first), command `0x24` (read) or `0x34` (write); for LBA28 the drive select `0xE0 | slave << 4 | lba[27:24]`, count, three LBA bytes, command `0x20` or `0x30`,
3. for each sector, a 400 ns delay, `wait(d, 1)`, then 256 words of `inw` or `outw` on the data port,
4. after a write, a cache flush: `0xEA` for LBA48 or `0xE7` for LBA28, followed by `wait(d, 0)`.

Interrupts are off for the whole chunk, including the transfer. The caller waits in programmed I/O. The buffer must be 2-byte aligned for the `u16` accesses and large enough for `count * 512` bytes. No retries are made, and the first error aborts the call after restoring interrupts. In QEMU this takes microseconds.

### The disk layout

The constants are in `kernel/disk.h`:

| Constant | Value | Meaning |
|---|---|---|
| `LBA_STAGE2` | 1 | Stage2 starts at sector 1 |
| `LBA_KERNEL` | 64 | Kernel image starts at sector 64 |
| `LBA_STATE` | 4096 | State header sector |
| `SLOT_SECTORS` | 2048 | One slot, 1 MiB |
| `MIN_SECTORS` | `LBA_STATE + 1 + SLOT_SECTORS * 5` = 14337 | Smallest drive `install-to` accepts |

| Sectors | Content |
|---|---|
| 0 | MBR (`boot/mbr.asm`), 512 bytes |
| 1 to 16 | Stage2 (`boot/stage2.asm`), 8192 bytes |
| 64 to 4095 | Kernel image, at most 4032 sectors |
| 4096 | State header |
| `4097 + slot * 2048` | Slot `slot`, for slot 0 to 4 |

Slot 0 is the root source. Slots 1 to 4 are the worlds of tabs 1 to 4 (`1 + tab`). `NSLOTS` is `1 + NTABS` = 5.

The MBR contains no partition table. The area from byte 446 to 509 is zero, and the signature `0xAA55` is at offset 510.

### Boot sector and stage2

`boot/mbr.asm` is 16-bit code at `0x7C00`. It saves `dl` (the BIOS boot drive) and reads 16 sectors from LBA 1 into `0x7E00` with INT 13h function `0x42` (extended read, through a disk address packet), then jumps to `0:0x7E00` with `dl` restored. On failure it prints `subverge: can't read stage 2` with INT 10h and halts.

`boot/stage2.asm` is assembled with `org 0x7E00` and padded to 8192 bytes. It begins with `jmp short start`, a `nop`, and an 8-byte aligned header:

| Offset | Field | Set by `install-to` |
|---|---|---|
| 8 | `magic`, the 8 bytes `SUBVERGE` | in the blob |
| 16 | `kernel_lba` | `LBA_KERNEL` |
| 20 | `kernel_sectors` | `ksectors` |
| 24 | `load_addr` | `_kernel_start` (the blob default is `0x100000`) |
| 28 | `bss_end` | `_kernel_end` |
| 32 | `entry` | `_start` |

The `SUBVERGE` magic at byte 8 of LBA 1 is how `persist_init` finds the home drive. Stage2 then:

1. sets up segments and the stack at `0x7C00`, saves `dl`,
2. enables A20 through port `0x92`,
3. reads the kernel with INT 13h `0x42` in chunks of up to 64 sectors into `LOW_BUF` (`0x10000`), advancing the segment by `count << 5` paragraphs,
4. queries the memory map with INT 15h `E820` (signature `SMAP`, 20-byte requests), storing each entry at `MMAP + 4 + 24 * n` with a size field of 20 in the dword before it, up to 32 entries,
5. takes `mem_upper` from the entry whose base is `0x100000` (length shifted right by 10),
6. builds the information block at `0x5000` as described above,
7. loads the GDT (null, 32-bit code `0x00CF9A000000FFFF`, data `0x00CF92000000FFFF`), sets PE, and far-jumps to a 32-bit routine,
8. in protected mode, copies `kernel_sectors * 512` bytes from `LOW_BUF` to `load_addr` with `rep movsb`, clears memory from the end of the copy to `bss_end`, loads `eax = 0x2BADB002`, `ebx = 0x5000` and jumps to `[entry]`.

On a read failure it prints `subverge: can't read the kernel` and halts. The kernel must be linked so that `_kernel_start` equals the address the image is copied to, because the image is a flat copy with no relocation.

### The state header

`kernel/persist.c` keeps one 512-byte header in memory, `hdr`, and writes it to `LBA_STATE`.

    struct state_header {
        char magic[8];          /* "SVSTATE1" */
        u32 len[NSLOTS];
        u32 sum[NSLOTS];
        u64 saves;
        u32 theme;
        char logo[24];
        u8 pad[...];
    };

A `_Static_assert` fixes the size at 512 bytes. `len[slot]` is the byte length of the slot's text and `sum[slot]` its checksum. `saves` counts slot writes. `theme` is the index into `themes[]`, and `logo` is the logo name.

The checksum is 32-bit FNV-1a: initial value `2166136261`, for each byte `h = (h ^ byte) * 16777619`.

### Finding the home drive

`persist_init` runs `disk_init` and then checks each present drive in order 0 to 3 with `is_home(n)`: read sector 1 and compare bytes 8 to 15 with `SUBVERGE`. The first match becomes `home` (the variable starts at -1). If there is no home drive, nothing is read or written for the rest of the session: `persist_save_*` return at once and `persist_load` returns `NULL`.

With a home drive, the header is read from `LBA_STATE`. If the read fails or the magic is not `SVSTATE1`, the header is zeroed and given the magic. Then `vga_theme(hdr.theme)` applies the saved theme and a non-empty `hdr.logo` is copied into `logo_name`.

### Loading and saving slots

`persist_load(slot, &len)` returns `NULL` if there is no home drive, the slot is empty, or `len` is larger than `SLOT_SECTORS * 512 - 1`. It allocates `sectors * 512 + 1` bytes, reads the sectors, verifies the checksum against `hdr.sum[slot]`, frees the buffer and returns `NULL` on mismatch, and otherwise terminates the string and returns it. The caller frees it with `kfree`. Slot 0 is loaded by `root_boot` and slot `1 + id` by `omega_main` on the first run of each tab.

`save_slot(slot, buf, len)` pads the buffer with zeros to a whole number of sectors, writes the slot's sectors, and only then updates `hdr.len`, `hdr.sum` and `hdr.saves` and writes the header. The header is last, so an interrupted slot write leaves the old header, whose checksum does not match the new data, and the next load of that slot returns `NULL`. The header write is a single sector.

`persist_save_tab(tab)` allocates a 1 MiB buffer with `kmalloc_try`, produces the source of the tab's world with `omega_source` (limit `SLOT_SECTORS * 512 - 512` bytes), and saves it to slot `1 + tab`. If the allocation fails, the world has no source, or the output is too large, nothing is written. `omega_source` returns 0 when the text does not fit. `omega.c` calls `persist_save_tab(current->id)` after every line that changed the world and after `undo` and `redo`, unless the shell is restoring from a saved slot (`W->restoring`).

`persist_save_root()` does the same for the root units through `root_source`, into slot 0, and is called by `kernel/root.c` after a successful root rebuild.

`persist_save_theme()` copies `vga_current_theme()` and `logo_name` into `hdr` under `irq_save` and writes only the header sector. The `theme` and `logo` words call it.

### `install-to`

`install-to` takes a drive number and does the following, failing with a message at the first problem:

1. the drive exists (`drives[n].present`), has at least `MIN_SECTORS` sectors, and the `.data` snapshot exists,
2. computes `text = _data_start - _kernel_start`, `total = text + snapshot_len` and `ksectors = ceil(total / 512)`; fails if `ksectors > LBA_STATE - LBA_KERNEL`,
3. builds the image: `memcpy` of `_kernel_start` for `text` bytes, followed by the `snapshot` of `.data`,
4. copies the 8192-byte stage2 blob and patches the header fields in the copy,
5. writes the MBR to sector 0, stage2 to sectors 1 to 16, the image to sector 64 and following,
6. clears `hdr`, gives it the magic, the current theme and logo, writes it to `LBA_STATE`,
7. sets `home = n`, saves the root and all four tabs.

The `.data` snapshot is taken at the very start of `kmain`, so the installed kernel starts with the initial values of its data. The text and read-only data are read from the running image, which is unchanged. The running `.data` is not used because it has been modified since boot.

`save` does `persist_save_root()` and `persist_save_tab(i)` for the four tabs, and fails if no home drive exists. `drives` returns a quote of `[ n model megabytes is-home ]` for each present drive. `home` pushes the home drive number or -1. `ask` reads a line with the line editor using a per-tab history.

The Makefile targets `run-install` (QEMU with `-kernel` and `build/disk.img` on an IDE controller) and `run-disk` (QEMU booting from the disk) exercise this code. `make disk` creates `build/disk.img` as a 64 MiB sparse file.

In the host build `persist_load` returns `NULL` and the save functions do nothing, as `test/host.c` defines them. Nothing in `persist.c` or `disk.c` is covered by `make host`.

## Panics and faults

### `panic`

`panic(msg)` in `kernel/cpu.c` is `noreturn`. It executes `cli`, fills all 25 hardware rows with spaces in `ATTR(C_BG, C_LRED)` (the background colour as foreground on light red), and writes three strings at column 2 on rows 1, 3 and 5: `panic`, the message and `halted`. Each string is cut off at 78 characters. It moves the hardware cursor to row 25, which hides it, and loops on `hlt` with interrupts off. The screen is drawn with `hw_put` directly, so it does not depend on the tab buffers or the heap, and it never returns.

`hw_put` writes nothing when `gfx_on` is set, so a panic in graphics mode halts the machine without showing the message.

The callers are:

| Source | Message |
|---|---|
| `kmalloc` when `kmalloc_try` returns `NULL` | `ran out of memory` |
| `kfree` on a block already marked free | `double free` |
| `task_fault` when `current->id < 0` | the exception message |
| other kernel code | the string passed in |

The host harness defines its own `panic` that prints `PANIC: <msg>` and exits.

### A tab fault

An exception while a tab is running calls `task_fault` and restarts that tab; the other three tabs keep running. The sequence:

1. `isr_handler` builds the message, for example `page fault at 0x0 (rip 0x1234ab)`.
2. `task_fault` copies it into `current->fault` (96 bytes), clears `wait_key` and `wake_at`, rebuilds the initial frame at the top of the tab's stack and returns it as the next `rsp`.
3. `isr_common` pops that frame and `iretq` enters `omega_main` again, on a clean stack, with interrupts on.
4. `omega_main` sets the title back to `omega`. The shell state in `W` still exists, so the saved-world restore is skipped. Because `current->fault[0]` is set it prints the message in light red as `! <message>`, then prints `your last line was dropped` in the dim colour, and clears `fault[0]`.
5. The prompt loop resumes, calling `gc()` before each prompt.

The world of the tab is whatever it was after the last line that completed. The line that faulted had not committed, since the world is advanced at the end of `eval_line`. The `your last line was dropped` message refers to that.

The text of the faulting line is not kept. The faulted tab's `term` buffer is not cleared, so earlier output stays on screen.

Because the stack is reset without unwinding, any resource held by the interrupted code is not released: heap blocks from plain `kmalloc`, the `mouse_on` flag, and any `wait_key` or `wake_at` (these two are cleared by `task_fault`). The `ed` and `calc` pointers are not cleared either.

### What does not recover

| Event | Result |
|---|---|
| Exception in the idle task (before the first tick, or in the `hlt` loop) | `panic` |
| Heap exhausted in `kmalloc` | `panic` |
| Double free | `panic` |
| Exception with an unusable stack | triple fault, machine reset |
| Exception inside an interrupt handler on a tab | `task_fault` restarts the tab; the interrupted IRQ's EOI was not sent |

## Checklist for kernel changes

1. Run `make host` and feed the affected words through `build/host`. Run `printf '@docs\n' | build/host` and expect `0 problems`. Remember that `kernel/cpu.c`, `kbd.c`, `disk.c`, `persist.c`, `font.c`, `main.c` and the assembly are not part of the host build (`HOSTSRC` in the `Makefile`), so a change in them gets no coverage from this step.
2. Run `make stress` for any change to the allocator, the shell, the garbage collector, a new built-in, or anything that holds a pointer across an allocation. A freed block is filled with `0xDD`, so a dangling use shows up as that pattern.
3. Build the real kernel with `make` and check that it still links with `-Wall -Wextra` clean. The flags forbid SSE (`-mgeneral-regs-only`) and the red zone (`-mno-red-zone`). Do not add floating point, `memcpy` variants that use vector registers, or code that assumes a red zone.
4. Boot with `make run` (`qemu -kernel build/subverge.elf -m 256M`). Check that all four tabs start, that F1 to F4 and Alt+1 to 4 switch, and that the tab bar clock advances.
5. Boot the ISO with `make run-iso`. A change to `boot/boot.asm`, to `linker.ld` or to the Multiboot header is visible here and in step 4 but a mistake in the header can pass one and fail the other. Check that `sys` shows the expected memory size.
6. If the change touches boot, `persist.c`, `disk.c`, the linker script or the size of `.data`, run `make run-install`, install to the drive, then boot it with `make run-disk`. Verify that the saved definitions, theme and logo return in the right tabs. Check the staging limit from the memory map section: the image must stay within `0x90000` bytes.
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

## The value cell

All omega data is made of one 24-byte cell, `V`, declared in `kernel/omega.h`.

    typedef struct obj { struct obj *all; u8 kind, mark, pinned; } obj;
    typedef struct { u8 t; i64 n; obj *p; } V;

The compiler (`kernel/jit.c`) depends on the layout: `VSZ` is `sizeof(V)` and the generated code copies a cell as three 8-byte moves. A change to `V` therefore needs a matching change in `copy_v`, `push_int_rax` and the `imul r12,r14,24` byte sequence in `sync_in`.

### Tags

The tag `t` is one of the `T_*` values. The table lists which field carries the payload.

| Tag | Value | Payload | Notes |
|-----|-------|---------|-------|
| `T_NONE` | 0 | none | Marks an absent value. `push` refuses it. A binding whose value is `T_NONE` is a tombstone left by `forget`. |
| `T_INT` | 1 | `n` | Signed 64-bit integer. `p` is NULL. |
| `T_STR` | 2 | `p` | Points to a `str`. |
| `T_QUOTE` | 3 | `p` | Points to a `quote`. Lists and code are the same type. |
| `T_SYM` | 4 | `p` | Points to an interned `str`. Written `'name`. |
| `T_WORD` | 5 | `p` | Points to an interned `str`. A name that is looked up and run. |
| `T_DEF` | 6 | `p` | Interned `str`. Written `:name`. Only meaningful inside a quote body. |
| `T_LOCALS` | 7 | `p` | Points to a `quote` whose items are `T_SYM` names. Written `{ a b }`. |
| `T_SET` | 8 | `p` | Interned `str`. Written `->name`. |
| `T_ORD` | 9 | `p` | Points to an ordinal object (`struct ord` in `kernel/ord.c`). |
| `T_CARD` | 10 | `n` | Cardinal. `p` is NULL. `n >= 0` is aleph-n. `n < 0` is 2 to the power aleph-(-n-1), so `continuum` is `n = -1`. |
| `T_BIG` | 11 | `p` | Points to a bignum object (`struct big` in `kernel/big.c`). |

Only `T_STR`, `T_QUOTE`, `T_SYM`, `T_WORD`, `T_DEF`, `T_LOCALS`, `T_SET`, `T_ORD` and `T_BIG` have a non-NULL `p`. `markv` in `kernel/omega.c` marks `p` whenever it is non-NULL, so a new tag that carries a pointer needs no change there as long as the object has one of the existing kinds.

The constructors are `I(n)`, `S(str *)` and `Q(quote *)`. `S(NULL)` and `Q(NULL)` return a `T_NONE` cell. This is deliberate: allocation failure makes `str_new` return NULL, and `push(S(str_new(...)))` then reports an error instead of storing a null pointer.

The `type` word maps tags to names in this order: nothing, number, string, list, symbol, word, word, word, set, ordinal, cardinal, number. `T_DEF` and `T_LOCALS` therefore report as `word`, and `T_BIG` reports as `number`. The error helper `want` has its own table of five names and prints `something else` for every tag above `T_SYM`.

### Object kinds

Every heap value starts with an `obj` header. The kind tells `mark` how to traverse it.

| Kind | Struct | Children traced by `mark` |
|------|--------|---------------------------|
| `O_STR` | `str` | none |
| `O_QUOTE` | `quote` | every `v[i]` |
| `O_BIND` | `bind` | `v` and the `next` binding |
| `O_ORD` | `struct ord` | the exponent of every term, through `ord_mark` |
| `O_BIG` | `struct big` | none |

The header fields are:

| Field | Use |
|-------|-----|
| `all` | Next object in the owning shell's allocation list (`W->objs`). NULL for pinned objects. |
| `kind` | One of the `O_*` values. |
| `mark` | Set during the mark phase and cleared by the sweep. |
| `pinned` | 1 when the object is never collected and never traced. |

### Strings, quotes, bindings and worlds

    typedef struct str { obj h; u32 len; void (*fn)(void); char s[]; } str;

`s` is NUL-terminated and `len` does not count the terminator. `fn` is the built-in attached to this name, or NULL. It is only used on interned strings.

    typedef struct {
        obj h;
        u32 n;
        u32 hits;
        void *jit;
        u32 jitlen, jitver;
        u8 nojit;
        V v[];
    } quote;

`n` is the item count and `v` the items. `hits`, `jit`, `jitlen`, `jitver` and `nojit` belong to the compiler ([the JIT](#the-jit)). A quote is never modified after construction except by the compiler fields. Words such as `append`, `cat` and `map` always build a new quote.

    typedef struct bind { obj h; str *name; V v; struct bind *next; } bind;
    typedef struct { quote *stack; bind *dict; } world;

A dictionary is a singly linked list of `bind` cells with the newest definition first. `define` allocates one cell and puts it in front of `W->dict`, so older worlds keep sharing the tail. A world is a pair of a stack snapshot, stored as a quote, and a dictionary pointer. The live interpreter state is in `struct omega` ([transactions](transactions.md), [worlds](worlds.md)).

### The interpreter state

`struct omega` holds everything that belongs to one shell tab. `W` is the macro `(current->om)`, so it always names the state of the task that is running. The fields that matter to a contributor:

| Field | Meaning |
|-------|---------|
| `objs`, `nobjs`, `ngc` | Allocation list of unpinned objects, its length, and the number of collections done. |
| `stk[STK]`, `sp` | The data stack and its depth. |
| `depth` | Current nesting of `run`. |
| `err`, `errmsg[96]` | Error flag and message. |
| `nback`, `nredo` | Counts requested by `back` and `redo` during the current line. |
| `pin` | When non-zero, `gnew` creates pinned objects and the collector and compiler are disabled. |
| `tracing`, `srcmode`, `restoring`, `shadowy` | Mode flags described below. |
| `dict` | The working dictionary of the line being run. |
| `loc[NLOC]`, `nloc` | The local name stack. |
| `cur`, `hist[HIST]`, `fut[HIST]`, `nhist`, `nfut` | The committed world and the undo and redo stacks. |
| `keep[256]`, `nkeep` | Extra collector roots. |
| `linequote` | The quote parsed from the current line. |
| `gc_threshold` | Object count that triggers a collection at the next safe point. |
| `src` | Parser cursor. |
| `lines` | The prompt's line history (`struct history`, `kernel/line.h`). |

The limits are constants in `kernel/omega.h`:

| Constant | Value | Effect |
|----------|-------|--------|
| `STK` | 1024 | Stack depth. `push` fails with `the stack is full`. |
| `HIST` | 64 | Undo and redo depth. |
| `DEPTH` | 400 | Nesting of `run`. Exceeding it fails with `this nests too deep`. |
| `NLOC` | 256 | Live local names. Exceeding it fails with `too many local names`. |

## Strings and symbols

### Allocation

`gnew(size, kind)` is the only allocator for collectable objects. It calls `kmalloc_try`, sets `kind`, clears `mark`, copies `W->pin` into `pinned`, and links the object into `W->objs` only when `pin` is 0. On failure it calls `fail("ran out of memory%s", "")` and returns NULL. Every caller that dereferences the result must test it. Callers that only push the result can rely on `S()` and `Q()` turning NULL into `T_NONE`.

`str_new(s, len)` allocates `sizeof(str) + len + 1` bytes, copies the bytes and appends a NUL. The string is an ordinary collectable object. Code that builds a string in place (`cat`, `replace`, the parser for string literals) calls `gnew(sizeof(str) + n + 1, O_STR)` itself and fills `len`, `fn = NULL` and `s`.

### Interning

`intern(s, len)` returns the unique `str` for a name. The table is a static array of `ITAB` = 8192 pointers with open addressing and linear probing. The hash is 32-bit FNV-1a with the offset basis 2166136261 and the prime 16777619. The slot for probe `k` is `(h + k) % ITAB`. A lookup stops at the first empty slot or at a slot with equal length and bytes.

A new entry is allocated with `kmalloc` (not `gnew`) and its header is `{ NULL, O_STR, 0, 1 }`: it is never in an allocation list, never marked and never freed. The whole call runs with interrupts off (`irq_save`). When all 8192 slots are taken and none matches, `intern` calls `panic("symbol table full")`. `intern_peek` does not exist. A caller that wants to know whether a name already exists has to call `intern` and test `fn` or `lookup` on the result; this also creates the entry.

Every distinct word in any parsed text, every `>sym` result and every symbol in an `eval` string takes a permanent slot. Equality of `T_SYM`, `T_WORD`, `T_DEF` and `T_SET` cells is pointer equality of `p`. The word `=` compares `T_STR` by length and bytes and every other type by tag and `p`.

### Attaching a built-in to a name

A built-in is a `str` whose `fn` field is non-NULL. `register_words(table)` walks a `struct builtin { const char *name; void (*fn)(void); }` array up to the entry with a NULL name. For each entry it calls `intern`, stores `fn`, and appends the string to a private array `builtins[512]` that the prompt completion uses. Entries past 512 still work but are not offered by completion. `kmain` in `kernel/main.c` and `main` in `test/host.c` call `register_words` for each module table in the same order.

Because the built-in lives on the name and not in a dictionary, a definition with the same name hides it without removing it. `exec_word` tries local names, then `lookup`, then `fn`. `define` increments `jit_version` when the name has an `fn`, because compiled code may have inlined the built-in ([the JIT](#the-jit)).

## Evaluation

### Parsing

`parse_text(text)` saves `W->src`, points it at the text, calls `parse(0)` and restores the cursor. The result is a fresh quote, or NULL with `W->err` set. The parser is recursive and works on a local array of 256 cells per nesting level. Its rules, in order:

1. Whitespace is space, tab, newline and carriage return. A `#` at the start of a token skips to the end of the line.
2. A token ends at whitespace or at any of `[ ] " { }`. A `#` inside a token is part of the token.
3. `[` starts a nested quote. The nesting limit is 32 (`the brackets are nested too deep`). A `]` without an open `[` fails with `there is a ] with no [ before it`, and a missing `]` fails with `a [ is never closed`.
4. `{ a b }` becomes one `T_LOCALS` cell. It takes up to 32 names and needs at least one. `}` alone fails with `there is a } with no { before it`.
5. `"` starts a string. The escapes are `\n`, `\t`, `\e` (byte 27), `\w` (byte 0x80), `\A` (byte 0x81). Any other character after a backslash stands for itself. A missing closing quote fails with `a string is never closed`.
6. Anything else is a token. `to_int` accepts an optional `-`, an optional `0x` or `0b` prefix and digits. It returns 1 for a value that fits in 64 bits, -1 on overflow and 0 when the token is not a number. On -1 the token goes to `big_parse` and becomes a `T_BIG`. Hexadecimal and binary literals larger than 2^63-1 are therefore bignums and are not wrapped.
7. A token that is not a number becomes a word. A leading `'` makes a `T_SYM`, a leading `:` a `T_DEF`, a leading `->` a `T_SET`. The prefix must be followed by at least one more character; `'`, `:` and `->` alone are ordinary words.
8. More than 256 items at one level fail with `that quote is too long`.

The line editor limits a line to `LINE_MAX` = 200 characters, so the 256-item limit is reached only by `eval` and the saved-world loader.

String and local-name cells are allocated while parsing. No collection can occur during a parse, because `gc_point` is only called from the run loop.

### The line quote

`eval_line(line)` in `kernel/omega.c` is the only entry point that runs user text. The shell loop, the saved-world loader and the `doc_run` buffer all call it. The steps:

1. Copy the committed stack into `W->stk` and set `sp`. Set `W->dict = W->cur.dict`.
2. Clear `err`, `nback`, `nredo`, `depth`, `nloc`, `tracing`, `nkeep` and `shadowy`, and clear the break flag (`kbreak`).
3. `parse_text(line)`. Store the quote in `W->linequote`, which is a collector root.
4. If a quote was produced, `run(q)`. Then clear `linequote`.
5. If `W->err` is set: discard pending keystrokes with `while (kbd_poll() >= 0)`, print `! message` in light red and return. Nothing was committed, so the committed world is unchanged.
6. If `W->nback` is non-zero: rewind (see [Transactions and history](#transactions-and-history)) and return. The effects of the rest of the line are discarded.
7. If `W->nredo` is non-zero: redo and return.
8. If the working dictionary pointer equals `cur.dict` and the stack equals `cur.stack` cell for cell, return. A line that changes nothing leaves no history entry.
9. Otherwise build a new stack quote, push the old world on `hist`, set `cur` to the new world, clear `fut`, and call `persist_save_tab` unless `W->restoring` is set.

The line quote starts with `hits = 0`, so it runs once in the interpreter and is never compiled.

### The run loop

`run(q)` is the interpreter:

    void run(quote *q) {
        if (jit_run(q)) return;
        if (++W->depth > DEPTH) { fail("this nests too deep%s", ""); W->depth--; return; }
        int base = W->nloc;
        for (u32 i = 0; i < q->n && !W->err; i++) {
            if (brk()) break;
            gc_point();
            if (W->tracing) { trace_step(q->v[i]); if (W->err) break; }
            exec_item(&q->v[i]);
        }
        W->nloc = base;
        W->depth--;
    }

`jit_run` returns 1 when it ran compiled code for the quote. `brk()` tests the task's break flag, clears it, and fails with `interrupted`. `gc_point` may collect. `exec_item` dispatches on the tag of the item:

| Tag | Action |
|-----|--------|
| `T_WORD` | `exec_word`. |
| `T_DEF` | Pop one value and `define` the name. Fails with `: needs more values on the stack` on an empty stack. |
| `T_SET` | Pop one value and `set_local`. |
| `T_LOCALS` | Pop one value per name, last name first, and push the names on the local stack. |
| anything else | Push the cell itself. A quote item is pushed as a value and not run. |

`exec_word(name)` resolves in this order: the local stack from the newest entry down (the value is pushed, not run), `lookup(name)` (the value goes through `call`), `name->fn`, and otherwise the failure `NAME isn't defined`. `call(v)` pushes a non-quote value and runs a quote. It adds the quote to the keep array for the duration so that it survives a collection while it runs.

### Failure

Errors are a flag and not an exception. `fail(fmt, a)` returns at once when `W->err` is already set, so the first error of a line wins. Otherwise it sets `W->err` and formats `errmsg` (96 bytes) with `snfmt`. Everything that runs afterwards checks the flag: `push` does nothing, `run` leaves its loop, the loops in `times`, `for`, `while`, `each`, `map` and `filter` stop, and compiled code jumps to its exit after every call into the runtime.

What is unwound on the way out is limited to the interpreter's own bookkeeping. Each `run` restores `nloc` and `depth` as it returns. Each built-in that called `keep` calls `unkeep` before it returns, including on error. The stack, the working dictionary and everything else stay as the failed line left them. They are discarded because `eval_line` never commits them. The built-ins that clear `W->err` themselves are `try` and `edit` (after the edited text fails to parse); `rebuild` in `kernel/root.c` clears it when a root build ends. `try` does not restore the stack or the dictionary: values pushed and names defined before the error remain. It prints the message, clears the flag and pushes 0, or pushes 1 on success.

The `fail` word calls `fail("%s", string)`.

### Tracing

`trace` sets `W->tracing` for the duration of one `call`. While it is set `run` calls `trace_step(item)` before each item. It prints the top six stack values, a marker, the item and the key help, then waits in `kbd_get`. `c` clears the flag and continues. `q`, Esc and Ctrl-C clear the flag and fail with `stopped`. Any other key steps once. `jit_run` returns 0 while tracing, so traced quotes run in the interpreter.

### srcmode

`omega_source` sets `W->srcmode` while it serialises a world. In that mode `repr` writes bytes 0x80 and 0x81 inside strings as `\w` and `\A`, and writes ordinals and cardinals as source text (`ord_source`) instead of the display form that uses font glyphs. The result can be parsed back by `eval_line`.

### shadowy

`set_local` and the `T_LOCALS` case set `W->shadowy = 1` when a local has the name of a built-in. `jit_run` returns 0 while the flag is set, for the rest of the line, because inlined built-ins in compiled code do not consult the local stack.

## Names and scope

### Dictionaries

There are two dictionaries. The tab dictionary is `W->dict` while a line runs and `W->cur.dict` between lines. The root dictionary is the global `root_dict`, built by `root_boot` from the units in `root/*.om` and shared by all tabs.

`lookup(name)` scans the tab dictionary for the first binding of `name`. If that binding's value is `T_NONE` the search for the tab ends and falls through to the root dictionary. If the value is anything else it is the result. A tombstone therefore hides every older tab binding of the name but not the root's. The root dictionary is then scanned the same way, and a tombstone there returns NULL.

`forget` checks that the name is bound in the current tab and then calls `define(name, none)` with a `T_NONE` value. It adds a tombstone, so it is undone by `back` like any other definition. `omega_source` skips tombstones and keeps only the newest binding of each name.

Completion, `words`, `see` and the world saver all depend on the "newest binding first" order.

### Definitions

`:name` pops a value and defines it. The binding is visible to the rest of the line and, if the line commits, to later lines. The value can be any cell. A definition whose value is a quote is run when the name is executed. A definition whose value is anything else pushes that value. To get a quote onto the stack without running it, use `'name get`.

Definitions made inside a quote take effect when the quote runs, in whatever dictionary is current. There is one working dictionary per line, so a definition made deep in a call is visible to the caller afterwards.

### Locals

`{ a b }` pops two values and creates two entries on the local stack `W->loc[NLOC]`: `b` takes the top value and `a` the one below. Each `{ }` always creates new entries, even for a name that already has one. `->name` pops a value and assigns it to the innermost existing local of that name. When none exists it creates a new entry.

Scope is dynamic. The local stack is one array, and `exec_word` searches all of it from the top down, so a word called from a quote sees the caller's locals. An assignment `->x` in the callee changes the caller's `x` when one exists. Every `run` truncates the stack to the length it had on entry, so locals die when the quote that created them returns. The quote's items are shared, not copied, so locals are not captured by a quote value that outlives the call.

A local named like a user definition shadows it in every callee. A local named like a built-in sets `shadowy` and keeps that line out of the compiler.

### Braces and the compiler

`T_LOCALS`, `T_SET` and `T_DEF` items cannot be inlined by the compiler. `inlinable` in `kernel/jit.c` returns 0 for a quote that contains one of them. Such a quote is still compiled as a whole; it is only never expanded in place inside an `if`, `when`, `times`, `for` or `while` form.

## Transactions and history

### The committed world

`W->cur` is the committed world. `eval_line` copies it into the working registers at the start of every line and replaces it at the end only on success. The history is two arrays of worlds:

| Array | Contents |
|-------|----------|
| `hist[HIST]`, `nhist` | Earlier worlds, oldest at index 0. |
| `fut[HIST]`, `nfut` | Worlds undone by `back`, newest undo at the end. |

Both hold at most `HIST` = 64 entries. When an array is full its oldest entry is dropped with `memmove`. A commit sets `nfut = 0`, so redo is available only until the next change.

### back and redo

`back` and `redo` do nothing themselves except increment `W->nback` and `W->nredo`. The count is applied after the line has run without error. `back` takes no argument; each use adds one to the count, so `back back` rewinds two lines. Rewinding moves `k = min(nback, nhist)` worlds: each step pushes `cur` on `fut` and takes the newest `hist` entry as `cur`. With `k = 0` the line prints `there is nothing to go back to`. Redo is symmetrical and prints `nothing to redo` when `fut` is empty. A successful rewind prints `rewound N` and a redo prints `redone N`. Both call `persist_save_tab` unless `restoring` is set.

Because the counters are applied at the end, everything else in the line is discarded when `back` is present, and an error anywhere in the line cancels the rewind.

### What a line commits

A line commits the stack and the dictionary. The new stack is copied into a fresh quote with `quote_new(W->stk, sp)`. The dictionary is only a pointer, because the working list already shares its tail with `cur.dict`. The cost of an entry in `hist` is one stack snapshot and the bindings added by the line.

### What is not undone

State that lives outside the stack and the dictionary is not part of a world and `back` leaves it alone:

| State | Where it lives |
|-------|----------------|
| Screen contents, cursor, colors, theme, logo | `kernel/vga.c`, `persist_save_theme` |
| Memory written by `poke`, `poked`, `pokeq`, memory from `alloc`, port output | machine state |
| The root dictionary and its units | `root_dict`, `kernel/root.c`; `open` and `unit` replace it and write it to the drive |
| Compiled code | the `jit`, `hits` and `nojit` fields of quotes |
| The symbol table | `itab` in `kernel/omega.c` |
| The state of `rand`, the tick count, the key queue | `hw.c`, `kbd.c` |
| Scrawl, calc and the doc viewer's own state | `scrawl.c`, `calc.c`, `doc.c` |
| Files on the drive | the state area of the disk ([disk-layout](disk-layout.md)) |

`persist_save_tab` stores only the committed world of the tab: the definitions oldest first, then the stack. `omega_source` writes at most 2048 distinct names (older ones are left out) and returns 0 when the text does not fit in a slot (`SLOT_SECTORS * 512 - 512` bytes), in which case nothing is saved. History is not saved. After a restore `omega_main` sets `nhist = 0`.

### Faults

A processor fault in a tab calls `task_fault` in `kernel/sched.c`, which stores a message in `current->fault` and restarts the task at `omega_main`. The tab keeps its `omega` state. The committed world is intact and the line that was running is lost. `omega_main` prints `! message` and `your last line was dropped` and goes on to the prompt.

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

Words written in omega itself live in `root/*.om` ([root-build](root-build.md)).

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

## Numbers

### Small integers and promotion

A number is a `T_INT` when it fits in a signed 64-bit integer. Anything outside that range is a `T_BIG`. The invariant is held by `norm` in `kernel/big.c`: every result of a bignum operation that fits in an `i64` is converted back to a `T_INT`. Two equal numbers therefore always have the same tag.

The `arith` function in `kernel/words.c` handles `+ - * / mod ^`. When both operands are `T_INT` it uses the compiler's overflow builtins (`__builtin_add_overflow` and the like). If the operation does not overflow the result is pushed. If it overflows, or if one operand is a `T_BIG`, the call goes to `big_arith(op, a, b)`. Division by zero fails with `division by zero`. The special case `-2^63 / -1` goes to the bignum path. `^` uses the integer path only for an exponent below 64 that does not overflow, and refuses negative exponents with `negative powers aren't supported`. Division truncates toward zero and the remainder has the sign of the dividend.

Anything else falls to `ord_arith`, which handles ordinals and cardinals. If that does not claim the operands either, the word fails with `+ needs numbers` (the message names the word).

The bitwise words `& | xor << >> ~` use `pop_int` and accept only values that fit in 64 bits. `not`, `and`, `or`, `if`, `when`, `unless` and `while` treat a bignum as true, which is correct because a bignum is never 0. `min`, `max`, `abs`, `neg`, `sqrt` and `gcd` accept bignums. `sqrt` uses Newton's method in integers on both paths.

### The bignum object

    typedef struct { obj h; u32 n; u8 neg; u32 d[]; } big;

The magnitude is `d[0 .. n-1]` in base 2^32, least significant limb first, with a separate sign flag `neg`. A normalised value has no zero limb at the top. `MAXL` is 2048 limbs, which is 65536 bits. `bnew` fails with `that number is too big, the limit is 2^65536` when asked for more.

Operations in `kernel/big.c`:

| Function | Operation |
|----------|-----------|
| `big_arith(op, a, b)` | `+`, `-`, `*`, `/`, `%`, `^` on any mix of `T_INT` and `T_BIG`. |
| `big_cmp(a, b)` | Three-way comparison of any two numbers. |
| `big_neg(a)` | Negation. `-2^63` is promoted. |
| `big_parse(t, l, &v)` | Reads a decimal, `0x` or `0b` literal. Used by the parser and `>num`. |
| `big_repr(o, v)`, `big_digits(v)` | Decimal output by repeated division by 10^9. `big_digits` is an upper bound for the buffer size. |

Addition and subtraction work on magnitudes (`madd`, `msub`) and the sign logic is in `signed_add`. Multiplication is the schoolbook method. Division is Knuth algorithm D (`mdivmod`), with a single-limb fast path. Exponentiation is square and multiply and rejects a result that would exceed `MAXL` limbs before it computes it. A bignum exponent is accepted only with a base of 0, 1 or -1.

Small operands are converted to a temporary two-limb `big` on the C stack (`of`) so that one routine handles every mix. A bignum is a collectable `O_BIG` object with no children.

### Ordinals

An ordinal below epsilon-zero is stored in Cantor normal form:

    struct oterm { ord *e; u64 c; };
    struct ord { obj h; u8 atom; u32 n; struct oterm t[]; };

The value is the sum of `omega^e * c` over the terms, in strictly decreasing order of the exponent `e`. An `e` of NULL stands for exponent 0, which is the finite part and is always the last term. The exponent is itself an `ord` (or a finite ordinal represented as a one-term `ord`). Coefficients are 64-bit.

Two atoms exist: `A_E0` (epsilon-zero) and `A_W1` (omega-one). They are `ord` objects with `n = 0` and `atom` set. They are allocated pinned by `ord_init` and returned by the words `epsilon0` and `omega1`. When an atom appears in arithmetic it is treated as a single term with coefficient 1.

Finite ordinals are ordinary `T_INT` cells. A result that is finite and below 2^62 is turned back into a `T_INT` by `ord_value`. A non-negative `T_INT` is converted to an `ord` with `fin()` for the operation. A negative integer fails with `ordinals are never negative`.

Rules in `ord_arith`:

| Operation | Behaviour |
|-----------|-----------|
| `+` | Non-commutative. Terms of the left side with an exponent below the leading exponent of the right side are dropped, and equal exponents merge. `1 omega +` equals `omega`. |
| `*` | Distributes over the terms of the right operand. |
| `^` | Handled by `power`, for finite and infinite bases. An exponent with a finite part above 64 fails with `that exponent is too big to write out`. |
| `-`, `/`, `mod` | Fail with `ordinals only support + * and ^`. |

A result keeps at most 64 terms (the `out[64]` arrays). A coefficient that overflows 64 bits fails with `that coefficient doesn't fit in 64 bits`. A bignum operand is accepted only where the result is determined by it (a bignum on the left of `+` or `*` gives the ordinal on the right); other mixes fail with `that number is too big to mix with an ordinal that way`.

Comparison is `cmp`: atoms compare by atom number, other values compare term by term, first by exponent and then by coefficient, and a shorter sequence that is a prefix of a longer one is smaller. `ord_compare` is called by `<`, `>`, `<=`, `>=` and `=` when an operand is an ordinal or a cardinal.

### Cardinals

A `T_CARD` stores its value in `n`: `n >= 0` is aleph-n, and `n < 0` is 2 to the power aleph-(-n-1). `aleph0` is `0`, `aleph1` is `1`, `continuum` is `-1`, and `2 aleph1 ^` is `-2`. A finite number is smaller than every cardinal.

Arithmetic in `ord_arith` for cardinals:

| Operation | Result |
|-----------|--------|
| `+`, `*` | The larger operand. `0` times a cardinal is `0`. If the order of the operands cannot be decided the word fails. |
| `^` with a finite base of at least 2 and a cardinal exponent of the aleph form | The power-set cardinal `2^aleph-k`. |
| `^` with a cardinal base and a positive finite exponent | The base. |
| any other `^`, and `-`, `/`, `mod` | Fail with `that cardinal power isn't supported` or `cardinals only support + * and ^`. |

`card_cmp` returns -1, 0 or 1 for a decided order. It returns 2 for "less than or equal, equality not decided", -2 for "greater than or equal, equality not decided" and 3 for "not decidable". This covers the cases that ZFC leaves open, such as aleph-1 against the continuum. The caller `answer` in `kernel/words.c` turns the result into a boolean for the operator when the answer does not depend on the open case, and otherwise fails with the message in the global `undecidable`.

## The JIT

### When a quote is compiled

`jit_run(q)` is the first thing `run` calls. It returns 0, and the quote is interpreted, when `jit_enabled` is 0 (`jit-off`), `W->tracing` is set, `W->shadowy` is set, or `W->pin` is set (root construction).

If the quote has code compiled under an older `jit_version`, the code is retired (queued on `dead[]`) and the quote is treated as not compiled. If the quote has no code, it is compiled only when `q->nojit` is 0 and the counter `++q->hits` has reached 2. A quote whose code was retired already has a count above 2 and is compiled again at once. The first run therefore interprets the quote, and the second run compiles it and runs the code. The counter is only incremented while the other conditions hold.

Compiled code then runs at once, between increments of the atomic `jit_running`, and `jit_run` returns 1.

`jit_version` starts at 1 and is incremented by `define` when the defined name has a built-in, and by `rebuild` when root changes. Every quote's code carries the version it was compiled under in `jitver`.

### What `compile` produces

`compile(q)` assembles into a static 64 KiB buffer, protected against reentry by a `busy` flag, then copies the result with `jit_alloc` (`kmalloc_try` in the kernel, an executable `mmap` in the host build). If the code does not fit, the nesting is deeper than 16 levels, the table of jump fix-ups (2048) overflows, or `jit_alloc` fails, `q->nojit` is set and the quote stays interpreted. `compile` is the only writer of `jit`, `jitlen` and `jitver`.

The register convention is fixed:

| Register | Holds |
|----------|-------|
| `rbx` | pointer to `struct omega` (`current->om`, read at entry) |
| `r13` | address of `W->stk[0]` |
| `r12` | address one past the top stack cell |
| `r14d` | cached `sp` |
| `r15d` | `nloc` at entry |
| `rbp` | frame pointer |

The prologue pushes `rbp`, `rbx`, `r12`-`r15`, subtracts 8 to align the stack, loads `W`, caches `sp`, saves `nloc`, increments `W->depth` and compares it with `DEPTH`. The epilogue stores `sp` back, restores `nloc`, decrements `depth`, restores the registers and returns. A disassembly of any compiled word begins like this (the absolute addresses differ in the kernel):

    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 0x8
    mov rbp, rsp
    mov rax, <address of current>
    mov rax, qword [rax]
    mov rbx, qword [rax+0x10d0]
    lea r13, qword [rbx+0x18]
    mov r14d, dword [rbx+0x6018]
    imul r12, r14, 0x18
    add r12, r13
    mov r15d, dword [rbx+0x80a8]
    inc dword [rbx+0x601c]
    cmp dword [rbx+0x601c], 0x190

The offsets `0x18`, `0x6018` and `0x601c` come from `offsetof(struct omega, ...)` and move whenever the fields of `struct omega` change. The generator uses `offsetof`, so only hand-written byte sequences such as the `imul` in `sync_in` need care.

### Inlining

`compile_seq` walks the items of the quote. A literal (`T_INT`, `T_STR`, `T_QUOTE`, `T_SYM`, `T_ORD`, `T_CARD`, `T_BIG`) is pushed inline with a bounds check; non-integer literals are copied from the quote's own cell, whose address is embedded in the code, so the quote must stay alive as long as its code. A `T_WORD` is inlined when `inline_word` knows it. Otherwise the code calls the runtime. Every other item type, such as `T_DEF`, `T_SET` or `T_LOCALS`, calls `h_item`.

A word is inlined only when its name has a built-in (`fn != NULL`) and `lookup` finds no user or root definition of it at compile time. The inlined words are:

| Words | Fast path | Slow path |
|-------|-----------|-----------|
| `+ - *` | Both tags are `T_INT` and the result does not overflow. | Any other case, including overflow, calls the built-in through `h_word` and so reaches the bignum code. |
| `& \| xor` | Both are `T_INT`. | `h_word`. |
| `< > <= >= =` | Both are `T_INT`. | `h_word`. |
| `dup over drop swap nip` | Stack depth is sufficient and there is room. | `h_word`, which reports the error. |
| `not neg` | The operand is `T_INT` (and `neg` does not overflow). | `h_word`. |

The control forms are expanded in place when their quotes are written literally before the word, each quote has at most 200 items and none of them contains `{ }`, `->` or `:`:

| Form | Code |
|------|------|
| `[ A ] when`, `[ A ] unless` | Pop an integer, test, run the body inline. |
| `[ A ] [ B ] if` | Pop an integer, two inline bodies. |
| `n [ A ] times` | Counter on the machine stack. |
| `a b [ A ] for` | Two counters on the machine stack; pushes the index each time and checks stack room. |
| `[ C ] [ B ] while` | Inline condition and body. |

If the condition is not an integer at run time, the code falls back to pushing the quote literals and calling the built-in through `h_word`. Nesting of inlined bodies is limited to 16 levels, beyond which the quote is marked `nojit`. A quote that is not inlined, such as the body of a `map`, is compiled separately when it is run twice.

### Calling the runtime

Compiled code calls C through absolute addresses loaded into `rax` (`call_abs`). Before each call `sync_out` writes `sp` back to `W->sp`. After the call `sync_in` reloads `sp` and recomputes `r12`, and then the code tests `W->err`; when it is non-zero it jumps to the epilogue. The helpers are:

| Helper | Calls |
|--------|-------|
| `h_word(str *)` | `exec_word`. |
| `h_item(V *)` | `exec_item`. |
| `h_push(V *)` | `push`. |
| `h_deep()` | Fails with `this nests too deep`. |
| `h_tick()` | `brk()` then `gc_point()`. |
| `h_whilebad()` | The error for a `while` condition that is not an integer. |
| `h_overflow()` | Fails with `the stack is full`. |

### Ctrl-C and errors

Straight-line compiled code contains no break check. Each iteration of an inlined `times`, `for` or `while` calls `h_tick`, which tests the break flag and gives the collector a safe point. `h_tick` sets `W->err` through `brk`, and the `err` test after the call leaves the loop. A built-in reached through `h_word` can also fail or stop with `brk`. The error flag is the only signal, so interpreted and compiled code report the same messages.

### Freeing code

The code of a quote is freed by `jit_forget` when the quote is collected. When `jit_version` changes, `jit_run` retires old code by moving the pointer to `dead[512]`, and `sweep` frees the entries once `jit_running` is 0, so code is not freed while any compiled function is on the stack. `rebuild` in `kernel/root.c` retires the code of every replaced root quote (`jit_release_one`) and then calls `jit_sweep`.

### nojit, compile, addr and jit

| Word | Effect |
|------|--------|
| `jit` | Prints whether the compiler is on, the number of compiled quotes and their total bytes. |
| `jit-on`, `jit-off` | Set `jit_enabled`. |
| `'name compile` | Compiles the quote bound to the name now, clearing `nojit` first, and leaves `addr len`. Fails with `NAME can't be compiled` if compilation is refused. |
| `'name addr` | The address of the quote's code, or of the C function of a built-in. |

### The disassembler

`kernel/dis.c` decodes a subset of x86-64 for reading the compiler's output. `dis1(p, addr, out, cap)` decodes one instruction at `p`, writes text to `out`, and returns the length in bytes. An opcode it does not know is printed as `db 0x..` with length 1. The decoder handles prefixes (`66`, segment, `lock`, `rep`), REX, ModRM and SIB addressing, the ALU group, `mov`, `lea`, `push`, `pop`, conditional and unconditional jumps and calls, `setcc`, `cmovcc`, `movzx`, `movsx`, `imul`, shifts, the string instructions, `neg`, `not`, `mul`, `div` and a few system instructions. Relative targets are printed as absolute addresses computed from `addr`.

| Word | Stack | Output |
|------|-------|--------|
| `dis` | `addr n --` | `n` instructions starting at `addr`. |
| `disr` | `addr bytes --` | The instructions in a byte range. |

`xray` and `jitdis` are defined in `root/70-dev.om`, not in C. `'name xray` prints the source with `see`, compiles the word with `compile`, prints the size and the address, and shows the first 16 instructions with `dis`. `'name jitdis` shows the whole range through `compile disr`. The host harness accepts `@dis name`, which writes the machine code of a compiled word to `build/dis.bin` and its disassembly to `build/dis.txt`, so the generator can be tested without QEMU.

When a change to `jit.c` is suspect, `jit-off` runs the same code in the interpreter. `make jit-test` runs `test/jit.qd` under QEMU through `build/qdrive`.

## The shell loop

### omega_main

`omega_main` is the entry point of each tab's task. The steps:

1. Set the tab title. If the state already exists, set `lines.complete` (this happens when a faulted task restarts).
2. If `W` is NULL, create it with `omega_init_world`, then load the saved world for the tab with `persist_load(1 + current->id, &len)` and run it through `eval_line` with `restoring` set. The history is cleared afterwards. `lines.complete` is set to enable Tab completion.
3. On tab 0 only: if `root_boot_error()` returned a message, print the system information and the error. Otherwise run `'startup defined? [ startup ] [ sys ] if` through `eval_line`, which runs the user's `startup` word or the default `sys`.
4. If `current->fault` holds a message, print it and the note that the last line was dropped.
5. Loop: `gc()`, `prompt()`, `readline`, `eval_line`, then the `doc_run` loop.

`prompt` writes the stack contents in dim text before the `>` mark. It shows the last 38 characters preceded by `..` when the text is longer than 40.

`readline` returns the length, or -1 when the user pressed Ctrl-C. A return of 0 or less skips evaluation.

### Boot order

`kmain` in `kernel/main.c` calls, in order: `persist_snapshot`, `vga_init`, `font_init`, `cpu_init`, the multiboot parser, `heap_init` (at most 64 MiB), `sched_init`, `persist_init`, `omega_init_world`, the ten `register_words` calls, `ord_init`, `root_boot`, `task_start` for each tab with `omega_main`, then the timer, keyboard and mouse. `omega_init_world` at this point creates the state of the idle task, not of a tab. `root_boot` runs with that state. Each tab creates its own state at the start of its first `omega_main`.

`root_boot` loads the saved root from the drive if there is one (slot 0), splits it into units at lines of the form `#>> name`, and calls `rebuild`. If the saved root does not build, the error `the saved root didn't build, using the built-in one` is recorded and the root linked into the kernel (`build/rootfs.bin`, the concatenation of `root/*.om` in name order) is built instead. `rebuild` runs the units with `W->pin = 1`, so all of their definitions and quotes are pinned, and an error in a unit is reported with the unit name.

### doc_run

The help viewer cannot call `eval_line` itself because it runs inside a built-in, in the middle of a line. When the user follows a link that runs code, the viewer copies the text to the global `char doc_run[200]` and returns. The loop in `omega_main` then repeats until the buffer is empty: copy the text to a local, clear the global, print it, and `eval_line` it. A line that runs `docs` again can therefore chain without recursion. The text is limited to 199 characters.

## The line editor and ask

### readline

`readline(char *b, struct history *h)` in `kernel/line.c` reads one line with editing. It works on the current screen row: the line can use at most `VW - x - 1` columns, where `x` is the cursor column at entry, and never more than `LINE_MAX` = 200. The line is redrawn after every key.

| Key | Action |
|-----|--------|
| Printable ASCII (0x20 to 0x7E) | Insert at the cursor if there is room. |
| Enter | Accept. The line is stored in the history unless it is empty or equal to the previous entry. |
| Ctrl-C | Print `^C` and return -1. |
| Backspace, Delete | Delete before or at the cursor. |
| Left, Right, Home, End | Move the cursor. |
| Up, Down | Step through the history. |
| Tab | Complete the name before the cursor. |

The history is the `struct history` passed in: `LINE_HIST` = 16 lines in a ring, kept per tab in `W->lines`. Up moves to older entries as long as they are still in the ring.

### Completion

Tab works only when `h->complete` is set. The word before the cursor is found by scanning left to the nearest of space, `[`, `]`, `{`, `}` and `"`. A leading `'` or `:` or `->` is skipped. A prefix is at most 62 characters and must be non-empty.

`complete_name(prefix, n, nth, out, cap, &lcp)` in `kernel/omega.c` collects up to 256 candidates: the names bound in the committed tab dictionary and not shadowed by a tombstone, the names in `root_dict`, and the registered built-ins. Duplicates are removed, the list is sorted by insertion sort, and the common prefix length is computed. It returns the count and copies the `nth` candidate (modulo count) to `out`.

If there is exactly one candidate it is inserted with a trailing space. If there are several and their common prefix is longer than what was typed, only the common prefix is inserted. Otherwise each further Tab press cycles through the candidates in sorted order. Any other key ends the cycle.

### ask

`ask` (`kernel/persist.c`) pops a prompt string, prints it in the moon colour and calls `readline` with a per-tab `struct history` kept in a static array. That history has `complete` equal to 0, so Tab does nothing, and Up and Down recall earlier answers to `ask`. The answer is pushed as a string. Ctrl-C fails with `cancelled`. The maximum answer length is `LINE_MAX`.

    "name: " ask

The prompt text is not part of the line, and the column where input starts is the cursor position after the prompt.

## The help system in code

### Tables

`kernel/help.c` defines two static tables.

    struct doc { const char *group, *name, *effect, *text, *example; };
    struct grp { const char *name, *text; };

| Field | Meaning | Limit |
|-------|---------|-------|
| `group` | Name of an entry in `groups[]`. | must exist |
| `name` | The word as typed, or for group `syntax` the syntax form. | |
| `effect` | Stack picture such as `a b -- c`. | 15 characters |
| `text` | One sentence, ending with a period. | 52 characters |
| `example` | A line to try. Words after three spaces are an explanatory note. | |

`groups[]` has 22 groups: `syntax`, `stack`, `math`, `logic`, `flow`, `lists`, `text`, `io`, `names`, `world`, `infinity`, `memory`, `ports`, `time`, `screen`, `machine`, `dev`, `tools`, `demos`, `games`, `util` and `helpers`. `docs[]` has one entry per word, including the words defined in root units; `NDOCS` and `NGROUPS` are computed from the array sizes.

The `effect` string is split at `--` by `plain_effect` for the sentence `takes X, leaves Y`. A word that takes or leaves nothing has an empty side.

### The words

`help` with no argument prints `overview`: the names in each group. It skips `helpers`, `syntax`, `tools`, `demos` and `games` in the overview. `'name help` prints the group page if the symbol is a group name, the word page if it is a documented word, or says that the name is the user's own if `lookup` finds it. Otherwise it fails with `there is no help for NAME`. `apropos` takes a string and lists every entry whose name or text contains it, ignoring case.

### Accessors for generated pages

The tables are static. `help_ngroups()`, `help_ndocs()`, `help_group(i, &name, &text)` and `help_doc(i, &group, &name, &effect, &text, &example)` at the end of the file are the interface that `kernel/doc.c` uses. `doc.c` builds pages on request:

| Page name | Generator | Content |
|-----------|-----------|---------|
| `word-index` | `gen_words(NULL)` | Every group with its words as links. |
| `a-to-z` | `gen_atoz` | All word names sorted, as links. |
| `?NAME` | `gen_word` | The word page: name, stack picture in code, text, example, and a link to the group. |
| `?group:NAME` | `gen_group` | One group with a line per word. |

The generators write Markdown into a 64 KiB buffer (`gstart`, `gput`) and the normal layout code turns it into a page. A name that contains Markdown punctuation is escaped by `word_link`.

### Pages from doc/

The files `doc/*.md` are concatenated by the Makefile into `build/docfs.bin`. Each file is preceded by a line `#>> name` where `name` is the file name without extension, and the result is linked into the kernel. `index_pages` in `kernel/doc.c` finds the lines that start with `#>> ` and builds a table of at most 400 pages with names up to 39 characters.

The layout supports a small dialect: headings, paragraphs, bullet and numbered items, tables, indented and fenced code, inline code, and links. A link target of the form `page` or `page#anchor` goes to a page, a target that starts with `?` goes to a word page, and one that starts with `>` runs the text after it at the prompt (a `~` stands for a space). A code line in which every word is known (built-in, root word, definition, number, string, `'x`, `:x`, `->x`, `{`, `}`) becomes a run link; text after three spaces is a note and is not run. The limits are `MAXLINES` 4000 lines, `MAXLINKS` 600 links per page, `MAXATOMS` 4096 inline atoms, and a text width of 76 columns.

The viewer reads keys with `kbd_get`: Up, Down, PgUp, PgDn, Space, Home and End scroll, Tab and Shift-Tab select a link, Left and Right select a link as well, Enter follows, Backspace goes back (16 entries), and `q` and Esc close. The mouse is enabled for the viewer through `current->mouse_on`.

### Checking pages

`make doccheck` runs `test/doclinks.py`. It reads every `doc/*.md`, takes each Markdown link target, strips `#anchor` and a trailing `.md`, and reports targets that are not the name of a page in `doc/` and are not `word-index` or `a-to-z`. Targets that begin with `?`, `>` or `http` are skipped, and targets that begin with `@` or `!` are reported. The script exits non-zero when it finds a problem.

`@docs` in the host harness checks `docs[]` against the registered words and the root dictionary, as described under [The docs check](#the-docs-check). Both checks have to pass before a commit that touches words or pages.

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

Root is the part of the system written in omega. It holds every utility, game and demo that is not a C builtin, and the strings the help system and the tour are made from. The source is the files `root/*.om`. A running system holds root as a list of units, each with its source text and the names it defines, and as one dictionary (`root_dict`, declared in `kernel/omega.h`) that every tab searches after its own definitions. The code is `kernel/root.c`. The user-facing description is in [root-build](root-build.md) and [units](units.md). This section describes what the code does.

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

### The dictionary chain and `root_dict`

A dictionary is a singly linked list of `bind` records, newest first. A name is looked up by walking the chain from the head and taking the first record with that name. Definitions in a unit are therefore pushed on the head, and a later definition of the same name hides an earlier one without removing it.

The lookup order for a name in a tab is: locals, the tab's own dictionary (`W->cur.dict`), `root_dict`, then the builtin function attached to the interned name (`str->fn`). A root word with the same name as a builtin hides the builtin for every tab. `rebuild()` detects this: after a successful build it walks the whole new chain and, for each binding whose name also has a builtin (`b->name->fn`), appends the name to `shadow_note` (`shadows: name name ...`, truncated before the buffer of 160 bytes is full).

Words are bound late. A quote refers to a word by interned name, and the name is resolved when the quote runs. A word may therefore call a word that is defined further down the same unit or in a later unit. The units that ship with the system define every word above its first use anyway, and that is the convention to follow.

### Unit order

Order matters in three places.

- A unit's top-level code runs during the build, so a word it calls at build time must already be bound. The shipped units only define words and do not call them, with `startup` the exception that is called from outside root.
- When two units define the same name, the later unit's definition is found first and hides the other. Both stay in `units[].words`.
- An edit rebuilds the edited unit and every unit after it (`start = which`). The units before it keep their bindings. Putting a word in an early unit makes an edit to it cost a rebuild of almost all of root. Putting it in a late unit makes the rebuild short.

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

### Limits

| Limit | Value |
|---|---|
| Units | 32 (`NUNITS`) |
| Names recorded per unit | 96 (`UWORDS`) |
| Unit name stored | 23 bytes |
| Unit name accepted by `unit` | 20 bytes |
| Error message of a failed build | 119 bytes |
| Shadow note | 159 bytes |
| Root text that can be saved | 1048064 bytes |

When a unit defines more than 96 distinct names the later ones are still bound and callable, but they are not recorded. `root` does not list them and `'name open` does not find the unit through them.

## A tour of every file in root/

Each subsection names the unit, lists the words it defines and says which are meant to be typed (public) and which only the unit uses (helpers). The split follows the groups of `kernel/help.c`: the group `helpers` holds the helpers, and every other group holds public words. A public word is shown in the overview of `help` or in the group page of its group. A helper is only found through `'helpers help`.

### Conventions used in the units

- A definition is `[ body ] :name`. The quote is evaluated first and `:name` binds the value on the stack to the name. A name starting with `:` in the source is a binding, not a call.
- Lists are quotes. `[ [ "a" "b" ] ] :names` defines a word `names` whose body is a quote that pushes the inner list. A table in a unit is written this way (`app-list`, `lessons`, `classes`, `edx-flags`, `month-names`).
- `{ a b }` at the start of a body pops values into locals, with the last name taking the top of the stack. Locals are dynamically scoped, so a helper called from the body sees them. The units avoid depending on this, with the exceptions below.
- `->name` assigns to an existing local, or creates one that lasts until the enclosing quote ends. The programs use it for loop state: `1 ->going`, `0 ->going`. Where a name must survive the quote, `:name` binds it in the tab instead (`todo-add` stores `todo-list` this way).
- A comment line begins with `#`. A comment after code is separated from it by spaces, and the units use it for stack effects (`# ch x y n c`).
- Helpers take their arguments on the stack and return through it. Dynamic scope is used inside one word: the quotes passed to `while`, `for`, `each` and `map` read the locals of the word that contains them, and that is how loop state such as `going`, `x` and `y` is shared between the body and the test.
- A full-screen program starts with `"name" title wipe nocursor` and ends with `wipe "omega" title`. `title` sets the label of the tab in the top bar and `"omega"` is the name the shell restores (`SHELL_NAME`). `wipe` clears the tab's screen. `nocursor` moves the hardware cursor off the screen (`vga_cursor(0, VH)`), so only the drawing shows.
- The loop of a program is `[ going ] [ ... ] while`, and the exit test is `k quit-key?` where `k` came from `key?` or `waitkey`. Keys are covered below.
- Drawing uses `put` (`c x y col put`), `text` (`s x y col text`) and `fill` (`ch x y n c fill`). Colours are numbers 0 to 15, resolved through the theme. `attr` combines them: `fg bg attr` leaves `fg + 16 * bg`.
- Padding uses `n pad`, where a positive `n` pads on the right and a negative `n` pads on the left. `fmt` is `x n fmt`: it turns `x` into text with `str` and pads it.

### Keys and the end of a loop

`key` waits for a key and pushes its code. `key?` pushes a code or `-1` without waiting. `waitkey` is `n waitkey`: it waits up to `n` ticks (hundredths of a second) for a key and pushes the code or `-1` on timeout. A program that redraws on a timer uses `waitkey` in place of `sleep` so a key press ends the wait at once.

`kernel/kbd.h` defines the special codes: `K_UP` is 256 (`0x100`), `K_DOWN` 257, `K_LEFT` 258, `K_RIGHT` 259, `K_HOME` 260, `K_END` 261, `K_PGUP` 262, `K_PGDN` 263, `K_DEL` 264, `K_MOUSE` 265, `K_BTAB` 266. `K_ESC` is 27. The programs use the numbers: `k 256 =` for up.

`quit-key?` in `00-core.om` is `k 113 = k 27 = or k 3 = or`: `q`, Esc or code 3, which is Ctrl-C. In `kernel/kbd.c`, Ctrl-C sets the `brkflag` of the active tab, and the code 3 is also put in the key buffer.

A set `brkflag` has a stronger effect than the key code. The interpreter loop (`run()`), `while`, `times`, `for`, `each`, `map`, `filter`, `sleep` and `beep` call `brk()`, which clears the flag and fails with `interrupted`. The line then ends as an error: it is rolled back, the keyboard buffer is drained (`while (kbd_poll() >= 0)` in `eval_line()`) and `! interrupted` is printed. The cleanup at the end of the program does not run. A program that must leave the screen tidy therefore needs the user to quit with `q` or Esc, and Ctrl-C stays an abort. A loop body that calls none of these still receives code 3 as a key, which `quit-key?` accepts.

### 00-core.om (`core`)

Shared helpers that nearly every other unit uses. It must be first.

| Word | Group | Effect |
|---|---|---|
| `inc`, `dec`, `sq` | util | add 1, subtract 1, square |
| `attr` | util | `fg bg -- n`, `fg + 16 * bg` |
| `>hex` | util | number as `0x` followed by hex digits |
| `fmt` | util | `x n -- s`, text of `x` padded to `n` |
| `kb`, `mb` | util | bytes as `K` and `M` text |
| `fill` | util | `ch x y n c --`, a row of `n` copies of a character |
| `bar` | util | `x y w pct c --`, a bracketed bar of width `w` filled to `pct` percent |
| `header` | util | `"title" --`, paints row 0 with the title at column 1 and `q quits` at column 72 |
| `quit-key?` | util | `k -- 1\|0`, true for `q`, Esc and Ctrl-C |
| `watch` | tools | `q --`, redraws the quote every half second until any key |
| `timeit` | tools | `q --`, runs a quote and prints ticks and cycles (`rdtsc`) |
| `sum`, `fold` | lists | sum of a list, fold with a quote |
| `uptime` | util | text such as `1h 2m 3s` from `ticks` and `hz` |

`watch` runs `wipe nocursor q do` and then `50 waitkey`; a key code other than `-1` ends it. Programs that only redraw, such as `irqmon`, are `[ ... ] watch` around the drawing quote. `fill` and `bar` are written for the 80-column text screen and assume it. In `bar` the characters are 219 for the filled part and 250 for the rest, with 91 and 93 (`[` and `]`) at the ends.

### 05-apps.om (`apps`)

| Word | Group | Role |
|---|---|---|
| `apps` | tools | prints the table of programs |
| `app-list` | helpers | the data: a list of `[ "name" "description" ]` pairs |
| `app-cell` | helpers | `e w --`, prints one entry |

`apps` does not look at the dictionary. It prints `app-list`. A program appears in `apps` only when its entry is in the list. The list is printed in two columns, filled column by column: with `n` entries the left column has `(n + 1) / 2` rows, and entry `r` is followed on the same line by entry `r + rows`. The name is padded to 11 characters and, in the left column, the description to 26. Descriptions in the list are at most 25 characters so that the right column lines up. The first line printed is `Programs you can run. Type a name, or 'name help to learn about one.`

### 10-sys.om (`sys`)

| Word | Group | Role |
|---|---|---|
| `sys` | tools | prints the logo and the system lines |
| `welcome` | world | the intro text shown at start-up |
| `startup` | helpers | `sys welcome`, run by tab 1 at boot |
| `logo-subverge`, `logo-haelide` | helpers | logos |
| `user`, `os`, `host`, `kernel-name` | helpers | strings shown by `sys`, each a quote that pushes a string |
| `memline` | helpers | used and total memory as text |
| `sys-width`, `sys-line` | helpers | width and printing of one logo line |
| `stat` | helpers | prints one labelled line to the right of the logo |

`sys` reads the name of the current logo with `logo@`, forms `logo-<name>`, and checks with `defined?`. If the word does not exist it falls back to `logo-subverge`. The quote is run with `get do` and leaves the list of lines. The width of the widest line (by `sys-width`) plus 5 is the column where the information starts. The loop runs `max(len, 9)` times. On each row it prints the logo line, moves to the information column with `where` and `cursor`, and prints the row's text: row 0 is `user@host` in colour 15, rows 1 to 6 are `os`, `kernel`, `uptime`, `shell`, `cpu` and `memory`, row 8 is a line of eight colour swatches. `stat` pads the label to 9 and cuts the value with `0 78 x - 9 - 0 max slice` so a long value does not wrap.

The strings `os` (`Subverge ...`), `kernel-name` (`ordinal ... x86_64`) and the `omega ...` text inside `sys` carry the version numbers. A release changes all three.

`welcome` branches on `home 0 <`, which is true when no home drive exists. The first branch says that nothing is saved on a live ISO. The second says that the tabs and the edits to root are saved after every line. `startup` is a separate word so a user can replace it with `'startup open`. The last line of `welcome` says so.

### 20-top.om (`top`)

`top` is a full-screen monitor. `row` is its helper: `label val y --` fills row `y` and writes the label at column 2 and the value at column 12. The program records `ticks`, `idle`, and the counts of IRQ 0 and 1 at the start, then in a `while` loop draws `cpu`, `idle` percent, heap use (`heap` leaves used and total), the kernel size (`kernel`), the state of each tab (`tab`, which leaves name, state, and whether the tab is the shown one), the counters from `stats`, the two IRQ rates and `uptime`. It waits with `50 waitkey` and recomputes the rates from the differences when at least one tick has passed. It ends on `quit-key?`. Note `-1 ->idlepct`: the first frame shows `--` until a second sample exists. The rows follow a fixed layout, with the bars at rows 3 and 4 drawn through `bar`.

### 30-inspect.om (`inspect`)

Inspectors that read the machine.

| Word | Group | Role |
|---|---|---|
| `pcils` | tools | PCI devices, one line each: bus, device, function, vendor, device, class |
| `memls` | tools | the memory map from the boot information |
| `cpuinfo` | tools | CPUID vendor, brand, family, model, stepping, feature flags, `cr0`, `cr3`, `cr4` |
| `irqmon` | tools | live interrupt counts of IRQ 0 and 1 |
| `hexview` | tools | `addr --`, a hex editor for memory |
| `vendor`, `classes`, `class-name`, `mem-type` | helpers | lookup tables and their accessors |
| `reg>str`, `edx-flags`, `ecx-flags`, `show-flags` | helpers | CPUID decoding |

The flag tables are flat lists of a name followed by a bit number: `[ "fpu" 0 "tsc" 4 ... ]`. `show-flags` takes a register value and a table and prints the names whose bit is set. `pci` and `memmap` are builtins that leave a list of lists, and the units walk them with `each` and `spread`. `irqmon` uses `watch`. `hexview` is the only unit program that edits memory with `poke`, and its loop reads keys with the blocking `key`. The movement keys are the arrow codes 256 to 259, PgUp and PgDn are 262 and 263, and digits `0` to `9` and letters `a` to `f` enter a nibble; the second nibble writes the byte at the cursor with `poke` and advances. One page is 336 bytes (21 rows of 16).

### 40-infinity.om (`infinity`)

The demonstrations of ordinals and cardinals.

| Word | Group | Role |
|---|---|---|
| `count` | demos | counts past every finite number, to `omega1` |
| `ord-demo` | demos | table of ordinal and cardinal facts |
| `pairing`, `hotel`, `rationals` | demos | countability demonstrations |
| `diagonal`, `supertask`, `ulam` | demos | full-screen drawings |
| `powerset` | demos | list of all subsets of a list |
| `pair`, `unpair`, `fusc`, `rational` | demos | Cantor pairing and the Calkin-Wilf sequence |
| `collatz`, `thue`, `prime?` | demos | small number functions used by the tour and by `ulam` |
| `show`, `fact` | helpers | print an ordinal in colour, print a label and the value of a quote |

`show` prints a value with `.`, which formats ordinals and cardinals. `fact` takes a label string and a quote, runs the quote and prints both. In `count` the strings contain `\w` and `\A`, which the parser turns into the font characters for omega (code `0x80`) and aleph (`0x81`). `count`, `pairing`, `hotel` and `rationals` print text and finish with `"omega" title`, while `diagonal`, `supertask` and `ulam` take the screen with `wipe nocursor` and wait for `key` at the end. `ulam` draws primes up to 480 on a spiral that starts at column 40, row 12.

### 50-fun.om (`fun`)

| Word | Group | Role |
|---|---|---|
| `snake`, `life`, `rain`, `tiles` | games | the programs |
| `fortune` | games | prints one line from `fortunes` |
| `fortunes` | helpers | the list of facts |
| `food-spot`, `draw-food` | helpers | snake helpers |
| `set-at`, `slide-row`, `move-board`, `spawn`, `moves?`, `can-move?`, `log2`, `tile-color`, `draw-tiles` | helpers | the logic of `tiles` |
| `left-lines`, `right-lines`, `up-lines`, `down-lines` | helpers | index tables for the four directions |

`snake` reads `key?` once per step, ignores a reverse (`dy 1 = not and`), and keeps the snake as a list of screen cells encoded as `y * 80 + x`. A step is `8 sleep`. The board is the screen: collisions are tested with `has` on the body list and with bounds on the text rows. `life` uses `alloc` for two byte arrays of `80 * 22` cells, reads with `peek`, writes with `poke` and releases both with `free` on exit. `rain` loops while `key? -1 =`, so any key ends it. `tiles` keeps the board as a list of 16 numbers and never mutates it: `set-at` returns a copy with one item replaced, and `move-board` slides a board and returns the new board with the score gained. A move is legal when the new board differs from the old one (`str` of both compared), which `moves?` tests.

### 55-mandel.om (`mandel`)

`mb-iter` takes a point in fixed point (65536 is 1.0) and a maximum number of iterations, and leaves the number of steps before the point leaves the circle of radius 2 (`262144` is 4.0 in the squared fixed-point scale). `mandel-at` takes `ox oy sc mx`, the origin, the scale and the iteration limit, and draws one frame at 80 by 23 cells. `mandel` shows three views in a row, waiting for a key between them, and `q` leaves at once. `mb-iter` is the word the tour (`'mb-iter xray`) and `bench` use as a real compute loop for the JIT.

### 56-toys.om (`toys`)

| Word | Group | Role |
|---|---|---|
| `sieve`, `bounce`, `sorting`, `stars`, `scribble` | games | the programs |
| `bounce-step`, `star-step`, `sort-col`, `scribble-hint` | helpers | one step of an animation, or a line of text |

The programs here are written as a pure step function plus a loop. `bounce-step` takes a ball as a list `x y dx dy c`, draws it and returns the next ball, and `bounce` does `balls [ bounce-step ] map ->balls`. `stars` does the same with fixed-point positions (a unit of 256). `sorting` and `sieve` keep their data in a `alloc` block and free it before they return. `scribble` is the program in root that reads the mouse and is described in the next section: it checks `mouse?` first and says `No mouse was found.` otherwise. The loops end on `key? -1 =` (any key) in `bounce` and `stars`, on `quit-key?` in `sorting` and on `q` only in `scribble`, which reads the digits `1` to `9` for the colour and `c` to clear.

### 57-tools.om (`tools`)

The everyday programs and the helpers they share.

| Words | Group |
|---|---|
| `clock`, `stopwatch`, `timer` | tools |
| `todo`, `todo-add`, `todo-done` | tools |
| `bases`, `ascii`, `colors`, `convert`, `password` | tools |
| `km>mi`, `mi>km`, `kg>lb`, `lb>kg`, `c>f`, `f>c` | tools |
| `date`, `month`, `cal` | tools |
| `pong` | games |
| `two`, `hms`, `mmss`, `todo-get`, `to-base`, `base-row`, `dec2`, `alphabet`, `password-of`, `leap?`, `month-days`, `first-weekday`, `month-names`, `month-of` | helpers |

- `clock`, `stopwatch` and `timer` poll with `waitkey` so the display updates without a busy loop. `timer` takes the seconds on the stack (`90 timer`) and ends when time is up with `Time is up. Any key leaves.`
- `todo-list` is created by `todo-add` with `:todo-list`, so it is a binding in the tab's own dictionary and is part of the tab's saved world. `todo-get` returns it or an empty list.
- The unit conversions use integer arithmetic and print two decimals through `dec2`. `100 km>mi` computes `100 62137 * 1000 /`, which is 6213, and `dec2` prints `62.13`.
- `first-weekday` is a closed formula (a Sakamoto-style table `[ 0 3 2 5 0 3 5 1 4 6 2 4 ]`) with 0 as Monday, `month-of` prints one month with the given day in colour 12, and `cal` uses `time` to find today.
- `date` and `cal` use `time`, which reads the CMOS clock. `time` crashes the host harness, so these words are tested in QEMU.
- `pong` is in this unit although it is a game; its help entry is in the `games` group.

### 60-install.om (`install`)

`disks` prints the table of drives from `drives`. `install` lists them, asks `Install on which drive?`, reads a number with `>num`, shows the model and size, asks for `yes` and then calls the builtin `install-to`. Any answer other than `yes` prints `Cancelled. Nothing was written.` Both words are in the `machine` group. `install-to` is the C builtin in `kernel/persist.c` that writes the bootloader, the kernel and the state, and it is what calls `persist_save_root()` for the first time.

### 70-dev.om (`dev`)

`jitdis` is `compile disr`, the disassembly of a compiled word. `xray` prints the source with `see` and then the machine code: `compile` leaves the address and length of the code and `a 16 dis` prints 16 instructions. `bench` runs a quote with `jit-off`, then with `jit-on`, prints both times through `timeit`, and drops any values the quote left, comparing the depth before and after. All three are in the group `dev`. They are covered in [jit](jit.md) and [dis](dis.md).

### 80-learn.om (`learn`)

| Word | Group | Role |
|---|---|---|
| `learn` | tools | `0 lesson` |
| `lesson` | tools | `n --`, runs the tour starting at lesson `n`, counting from 0 |
| `lessons` | helpers | the data: a list of lessons, each a list of three strings |

The structure of the lessons and the way to add one are in the section The learn tutorial.

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

Run `wander`, move with the arrows, and click in the QEMU window to check the mouse branch. Press `q`, and check that the prompt and the tab label come back. Press Ctrl-C while it runs and check that `! interrupted` is printed. Check `apps` and `'wander help`. A drive that was installed from an older build holds its own copy of root and does not show the new unit (see Persistence in an installed system above). `test/qdrive.c` and the `*.qd` scripts drive a QEMU instance for automated runs; see [testing](testing.md).

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

### Logos

A logo is a word `logo-<name>` that pushes a list of lines. In `root/10-sys.om`:

    [ [
      "   _.--._"
      " .'  .-'"
      [ "/   /  " "/\\_/\\" ]
      ...
    ] ] :logo-subverge

A line is a string or a list of strings. A list is printed with its strings in colours 14 and 15 alternately, which is how the cat in `logo-subverge` has a different colour from the moon. `sys-width` returns the length of a string, or the total length of the strings of a list, and `sys-line` prints a line. The comment above the first logo states the rule. A backslash in a string is written `\\`.

How `logo` finds them:

- The current logo name is the C array `logo_name[24]` in `kernel/hw.c`, initially `subverge`. `logo@` leaves it as a string.
- `'name logo` (`b_logo()`) accepts the name when it is shorter than 24 characters and `has_logo()` finds the word `logo-<name>` with `lookup()`. The lookup covers the tab's dictionary and root, so a user can define a logo in a tab and select it. Otherwise it fails with `logo-<name> isn't defined, type logos to see the logos`. On success the name is saved with `persist_save_theme()`.
- `logos` walks `root_dict` and the tab's dictionary and lists every binding whose name starts with `logo-`, without duplicates, with `>` on the current one.
- `sys` builds the word name with `"logo-" logo@ cat >sym`, tests `defined?`, and uses `logo-subverge` when the word does not exist (for example after the user forgot a tab logo).

`sys` places the information column at the widest line plus 5 and draws at least 9 rows (`art len 9 max`). A logo may be any number of rows and any width up to about 60 columns, since the information needs about 30 columns on the right. `stat` cuts values that do not fit.

To add a logo:

1. Write the art with a fixed-width layout. Pad nothing: `sys-width` takes the longest line.
2. Add `[ [ ... ] ] :logo-<name>` to `root/10-sys.om`.
3. Add a row to `help.c` in the `helpers` group (for `logo-subverge`: `The cat and moon logo, as a list of lines.`). Without it, `@docs` reports `undocumented root word`.
4. Test with `'name logo sys` in `build/host` and look at the screen in QEMU.
5. Mention it in `doc/logos.md`.

`sys-line` and `sys-width` accept only strings and lists of strings. A logo word with another content fails at `sys`.

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

### Colours of links

`link_attr()` chooses the colour from the kind:

| Kind | Colours (foreground on background) |
|---|---|
| word | blue on background |
| run | teal on bar |
| page, not yet opened | light red on background |
| page, opened | mauve on background |
| selected | background colour on peach, or on moon for a run link |

The set of opened pages is `seen[400]`, one byte per page, set in `load()` when a page is opened. It lives as long as the kernel runs, is not saved and is shared by the tabs. A link to `#anchor` takes its colour from the page that is open. Generated pages are not marked. Pages that do not exist are drawn as unopened.

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

### Layout limits

| Constant | Value | Meaning |
|---|---|---|
| `VW`, `VH` | 80, 24 | text columns and rows of a tab |
| `VIEW` | `VH - 2` = 22 | rows of text shown between the two bars |
| `CW` | 76 | right edge of wrapped text, in columns |
| `LX` | 2 | left margin |
| `MAXLINES` | 4000 | lines per page; layout stops at `MAXLINES - 8` |
| `MAXLINKS` | 600 | links per page; links past it are drawn as plain text |
| `MAXATOMS` | 4096 | characters in one block (a paragraph, heading, list item or quote); the rest is dropped |
| `MAXCOL` | 8 | table columns |
| table cell | 240 characters, 16 lines | longer text is cut |
| table rows | 64 | rows in one table; a longer table continues as a second table, whose second row is dropped as a separator |
| anchors | 64 per page, names of 38 characters | |
| history | 16 positions | older ones are dropped |
| page name | 39 characters; the current name is kept in 47 |
| link target | 95 characters | |
| generated page | 64 KiB | the buffer for the index |

A paragraph is wrapped at `CW - LX` = 74 columns. A list item is wrapped at `CW` minus its indent. A quote is wrapped at 72. Words longer than the line are cut at the edge. Code lines are not wrapped and are cut at column 79.

Each line of a page is a `struct dline` of 80 cells and 80 link ids (320 bytes), allocated with `krealloc` in steps that start at 256 lines and double. A page of 4000 lines uses about 1.2 MiB of heap. The memory is freed when the pager closes.

### Tables

A table is a run of lines that start with `|` (after optional spaces). The second row is always skipped as the separator row, whatever it contains, so every table needs one. The first row is the header, in moon colour, followed by a line of dashes. `split_row()` cuts a row at bars that are not escaped and trims spaces around each cell.

`table()` measures every cell after inline formatting, so the width counts displayed characters, not source characters. The columns are separated by two spaces. If the sum of the widths plus separators is more than `CW - LX` = 74, the widest column (checking the columns from the second on, with the first used as the starting maximum) is reduced by one at a time until the table fits or the widest column is 8. Cells that are wider than their column wrap at spaces over at most 16 lines, and the row grows to the tallest cell. A table with more than 8 columns, or whose narrowest possible form is wider than 74 columns, is cut at the right edge.

Links in a cell work like links elsewhere. Header cells are moon coloured unless they are links.

### Generated pages

Four kinds of page are made on demand from the table in `kernel/help.c`, using the same layout code. They share one buffer (`gb`) that is replaced on each load, and they are not marked as opened.

| Name | Made by | Content |
|---|---|---|
| `word-index` | `gen_words(NULL)` | every group as a heading with its text and a row of word links |
| `a-to-z` | `gen_atoz()` | all words sorted by name, as word links |
| `?name` | `gen_word()` | the word, `( effect )` in code, the text, the example as an indented block (a run link if it is runnable), and a link to the group |
| `?group:name` | `gen_group()` | a heading and one line per word: link, effect in code, text |

`word_link()` escapes the characters that the inline parser reads (`[ ] \ \` * _ < |`) when it writes a word name as link text, so words such as `[ ]` and `|` have working pages. The overview printed by plain `help` is C code in `overview()` and does not use the pager.

### The pager

`open_page()` loads the page, switches the mouse events on for the tab (`current->mouse_on = 1`) and loops on `kbd_get()` calling `draw()` first. `draw()` paints the top bar (`doc`, the title, `q quit  bksp back`), the 22 text rows, and the bottom bar. The bottom bar shows the target of the selected link with `page:`, `word:` or `run:`, or the hint `tab link  enter follow  space next page`, and the position as a percentage.

| Key | Action |
|---|---|
| `q`, Esc | leave |
| Up, Down | scroll one line |
| PgUp, PgDn, Space | scroll 21 lines |
| Home | first line, clears the selection |
| End | last page |
| Tab, Shift-Tab | select the next or previous link (the first one on screen when nothing is selected) |
| Right, Left | the same as Tab and Shift-Tab. The first press selects a link |
| Enter | follow the selected link |
| Backspace | back |

With a mouse, the wheel scrolls by three lines per notch, the left button on a linked cell follows that link, and the right button goes back. A click on the tab bar switches tabs even in the pager. A run link or a click on a run line closes the viewer and sets `doc_run`.

History is the array `hist[16]` of page name, top line and selected link. `push_hist()` is called before a page or word link is followed, and when the array is full the oldest entry is dropped. `back()` reloads the page and restores the position and the selection. An anchor-only link does not push history and a page that fails to load restores the old one. On exit the page memory is freed, the screen is cleared and the tab title returns to `omega`.

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

### The docs check in the host build

`@docs` in `build/host` calls `help_check()` in `kernel/help.c`. It is built only with `-DHOST`. It checks the table against the words, not the markdown:

- every builtin in `core_words`, `hw_words`, `ord_words`, `root_words`, `persist_words`, `jit_words`, `dis_words`, `help_words`, `doc_words` and `mouse_words` has a row (`undocumented builtin: <name>`);
- every non-empty binding in `root_dict` has a row (`undocumented root word: <name>`);
- every row, except the group `syntax`, names a word that exists (`doc for a word that doesn't exist`), has a known group (`bad group on <name>`), a text of at most 52 characters (`text too long`) and an effect of at most 15 (`effect too long`).

It prints the number of problems. The result is `0 problems` on a clean tree. A new builtin without a row, a new root word without a row and a row that names a misspelled word are all found here, and a change to a word's name needs the row changed with it. Run both checks:

    make doccheck
    make host && printf '@docs\n' | build/host

The first prints `0 problems`, and so does the second. A third check is a build of the ISO or `make`, which fails on a C error but does not read the pages. `build/host` loads `build/docfs.o`, so a malformed `#>>` separator shows up as a missing page in `"name" doc`.

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

The in-system pages and the website pages in `src/*.md` of the site repository are different files with the same format. The site pages are built by `build.sh` into HTML and carry the site header and footer. A page that exists in both places is changed in both. In-system links name the page (`[keys](keys)`), and the site pages link with `name.md`. The pager removes `.md` from a page link, so `[keys](keys.md)` also works in `doc/`, and `doc/themes.md` already uses that form. See [docfs](docfs.md), [help](help.md) and [source-layout](source-layout.md).

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

### Running out of keys

A word that waits for a key would block forever in a program with no keyboard. The host replacements of `kbd_get` and `kbd_poll` use the global `jmp_buf out_of_keys` instead:

- `kbd_get` with an empty queue calls `longjmp(out_of_keys, 1)` at once.
- `kbd_poll` with an empty queue returns -1 and counts the empty polls in `empty_polls`. The 3001st consecutive empty poll longjmps. The counter is reset by every key that is delivered. A loop that polls with `key` and does other work between polls therefore runs 3000 times before it is cut off.

The jump target is set with `setjmp` around the `eval_line` call for ordinary lines and around `readline` for `@readline`. When it fires, the harness prints `(ran out of keys during: line)` or `readline: ran out of keys`. The interrupted line is not committed, since `eval_line` never reached its end, and the stack line that follows shows the world as it was. The next `eval_line` resets `W->err`, `W->depth`, `W->nloc`, `W->nkeep` and the other per-line fields, so the interpreter state is usable again. Memory allocated by the aborted line stays on the object list until the next collection.

`waitkey` is the exception, since it polls with a timeout: it returns -1 after the fake time runs out (the call yields, which advances the clock) and the line continues.

### `@dis` and `@roundtrip`

`@dis name` looks up `name`, and if it is a quote that has been compiled it writes the machine code to `build/dis.bin` and the listing from `dis1()` to `build/dis.txt`, one `offset: mnemonic` line per instruction. A quote is compiled when it runs for the second time, so run it a few times first:

    [ dup * ] :sq
    10 [ 5 sq drop ] times
    @dis sq

If the word has no code the harness prints `@dis: no code`. The directory `build/` must exist.

`@roundtrip` calls `omega_source` on the current world and prints `---- saved world (N bytes) ----` followed by the text. It then creates a fresh world with `W->restoring = 1`, evaluates the text in it, saves that world again and prints `roundtrip MATCHES` or `roundtrip DIFFERS` with the second text. This is the code path `install` and `save` use to write a slot, and a value type that does not survive it shows up here. The old world is dropped and not freed.

`@docs` and the docs check are described in [testing](testing.md).

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

### The scripts in `test/`

All scripts write PNG files to `build/`. The first column is the file.

| File | Boot it with | What it does |
|---|---|---|
| `boot.qd` | an installed disk | waits 5 s and shoots `s-disk.png` |
| `iso.qd` | the ISO | `2 omega * 1 +`, shoots `iso-boot.png` |
| `startup.qd` | the ISO | shoots the live welcome (`s-live.png`), `help` (`s-help.png`), an error set `1 0 /`, `foo`, `[ 1` (`s-errs.png`), then `install`, `0` (`s-inst.png`) and `yes` |
| `welcome.qd` | the ISO plus a blank disk | runs `install`, `0`, `yes` and no screenshots |
| `install.qd` | a kernel plus a blank disk | `install`, `0`, `yes`, shoots `inst.png` |
| `isoinst.qd` | the ISO plus a blank disk | defines `sq` and a 7 omega sum, installs and shoots `iso-inst1.png` and `iso-inst2.png` |
| `jit.qd` | `-kernel build/subverge.elf` | defines `fib`, benchmarks `24 fib`, shoots `p4-bench.png`, runs `'fib xray` (`p4-xray.png`), then a `while` loop `spin`, stops it with `ctrl-c` and shoots `p4-break.png` to show the line was interrupted |
| `help.qd` | any | `help`, shoots `p4-help.png` |
| `gfx.qd` | QEMU with a Bochs display | `gfx 20 20 100 60 5 box key drop gfx-off`: draws a box, shoots it, sends `a` to leave, and then runs `"back" say` to check that the text screen was restored (`gfx-ex1.png` to `gfx-ex3.png`) |
| `win.qd` | the same | draws a window with `window` and `text`, shoots `win1.png` |
| `shots.qd` | the ISO | the set of reference screenshots 01 to 23: welcome, help, a group, a word, ordinals and errors, `trace`, `back`, `sys`, `pcils`, `memls`, `cpuinfo`, `irqmon`, `hexview`, `calc`, the JIT xray and bench, `count`, `ord-demo`, `diagonal`, `supertask`, `pairing`, `root` and `'top open` |
| `shots2.qd` | the ISO plus a blank disk | tabs and games (`snake` on F2, `life` on F3, `rain` on F4, `top`), `fortune`, `words`, then an install (`25-snake.png` to `31-installed.png`) |
| `shots3.qd` | the installed disk | boots the disk and checks that the world came back (`32-installed-boot.png`, `33-world-restored.png`) |
| `shots4.qd` | the ISO | the welcome, `'map help` and the first lessons of `learn` |
| `shots5.qd` | the ISO | `learn`, `apps`, the toys (`sieve`, `bounce`, `sorting`, `stars`) and an edit of the `apps` unit |
| `shots6.qd` | the ISO | interactive `learn` lessons, `apps`, `"mine" unit`, `root`, `clock`, `stopwatch`, `timer`, `todo`, `bases`, `convert`, `ascii`, `colors`, `password`, `pong` |
| `shots7.qd` | the ISO | every theme with the same three lines (`sys`, a sort, an error), `logos`, a user logo and `themes` (`80-theme-*.png`, `86-logos.png`, `87-logo-mine.png`, `71-themes.png`) |

`test/doclinks.py` is not a QEMU script. `make doccheck` runs it and it reads `doc/*.md`, printing every link whose target page does not exist, every link of a kind the pager does not handle (`@` or `!`) and the total as `N problems`. The pages `word-index` and `a-to-z` are accepted as generated pages. It exits with status 1 when there are problems.

`make jit-test` is the one `qdrive` use that is wired into the Makefile:

    jit-test: build/subverge.elf build/qdrive
        build/qdrive test/jit.qd -- qemu-system-x86_64 -kernel build/subverge.elf -m 256 -no-reboot

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

## Driving QEMU by hand

The QEMU monitor is the main debugging tool for the kernel, since there is no serial console or log in it. Start QEMU with the monitor on the terminal:

    $ qemu-system-x86_64 -cdrom build/subverge.iso -boot d -m 256M -monitor stdio

or on a socket, from which `qdrive` style tools can talk to it:

    $ qemu-system-x86_64 -kernel build/subverge.elf -m 256M -monitor unix:/tmp/m.sock,server,nowait
    $ nc -U /tmp/m.sock

`make run` runs `-kernel build/subverge.elf -m 256M`, which skips GRUB and the ISO; `make run-iso` runs the ISO; `make run-install` boots the kernel with `build/disk.img` attached as `-drive file=build/disk.img,format=raw,if=ide` so that `install` has a target; `make run-disk` boots from that image alone. The kernel supports IDE only ([drives](drives.md)), so a disk attached as virtio or NVMe is not found.

### Monitor commands that are useful

| Command | Use |
|---|---|
| `sendkey ret`, `sendkey ctrl-c`, `sendkey f2`, `sendkey alt-3`, `sendkey shift-1` | type a key. Names are QEMU's: `spc`, `ret`, `esc`, `backspace`, `tab`, `up`, `down`, `left`, `right`, `home`, `end`, `pgup`, `pgdn`, `delete`, `f1` and up, `minus`, `equal`, `bracket_left`, `grave_accent`, `shift-`, `ctrl-`, `alt-` as prefixes |
| `mouse_move dx dy [dz]` | relative pointer movement (and the wheel with `dz`) |
| `mouse_button mask` | 1 left, 2 right, 4 middle, 0 releases |
| `info mice` | lists the mouse devices the guest has |
| `screendump file.ppm` | writes the current screen as a PPM file |
| `info registers` | the registers of the current CPU: `RIP`, `CR2`, `CR3`, `RSP`, `EFER` and the flags |
| `x /16xb 0xb8000` | virtual memory at an address as bytes; `/8xg` for 64 bit words, `/4i addr` to disassemble |
| `xp /8xw 0x20000` | physical memory |
| `info mem` and `info tlb` | the page mappings the guest installed |
| `info pic` and `info irq` | interrupt controller state and interrupt counts |
| `info qtree` | the devices on the machine |
| `stop` and `cont` | halt and resume the guest |
| `system_reset` | reset the machine |
| `quit` | leave QEMU |

`x /16xb 0xb8000` shows the text screen cells, which are character and attribute bytes. The kernel's own heap starts after `_kernel_end`, which `nm build/ordinal.elf | grep _kernel_end` gives. The page tables are the three tables in `boot.asm`: 4 GiB identity-mapped with 2 MiB pages.

### Options that help

| Option | Use |
|---|---|
| `-display none` | no window; combined with the monitor and `screendump`, this is how `qdrive` runs |
| `-d int,cpu_reset -D /tmp/qemu.log` | logs every interrupt and exception and the CPU state at each reset to a file |
| `-no-reboot` | exits on a triple fault instead of restarting, which keeps the log of the fault at its end |
| `-s -S` | opens a gdb server on port 1234 and stops the CPU before the first instruction |
| `-serial stdio` or `-serial file:/tmp/ser.txt` | connects the guest's COM1 to the terminal or a file |
| `-vga std` | the card `gfx` needs (the default of recent QEMU versions) |
| `-rtc base=localtime` | makes the tab bar clock show local time |
| `-m 256M` | the memory size the tests use; the kernel reads it from Multiboot and puts a heap of at most 64 MiB behind itself |
| `-cdrom build/subverge.iso -boot d` | boot the ISO |

### The serial port

The kernel has no serial driver and writes no log. The first byte written to port `0x3F8` is emitted by QEMU's 16550 without initialisation, so `out` can be used for one-off output from the guest:

    72 0x3f8 out  105 0x3f8 out

With `-serial file:/tmp/ser.txt` the file then contains `Hi`. A root word or a built-in under development can use the same trick to log values that the screen cannot show, for instance from code that runs while graphics mode is on.

### gdb

QEMU's gdb server needs `-s -S`. The kernel image `build/ordinal.elf` contains the symbols (the build has no `-g`, so there are function names and no source lines):

    $ qemu-system-x86_64 -kernel build/subverge.elf -m 256M -display none -s -S -no-reboot &
    $ gdb -q build/ordinal.elf
    (gdb) target remote :1234
    (gdb) hbreak kmain
    (gdb) continue
    (gdb) bt
    (gdb) hbreak isr_handler
    (gdb) continue
    (gdb) info registers rip
    (gdb) x/8i $rip
    (gdb) x/16xg $rsp

Use `hbreak`, not `break`: the CPU starts in 32 bit protected mode and a hardware breakpoint survives the switch to long mode. `hbreak kmain` stops after `boot.asm` has entered long mode (`bt` shows `long_mode` as the caller). `hbreak isr_handler` stops at every interrupt, and with the timer on that is 100 stops a second. To catch faults only, use `hbreak task_fault`, which `isr_handler` calls for every exception below vector 32 after it has built the message.

To find where a fault happened, take the `rip` from the red message and resolve it:

    $ gdb -batch -ex 'info symbol 0x1234ab' build/ordinal.elf
    $ nm -n build/ordinal.elf | awk '$1 <= "00000000001234ab"' | tail -1

A `rip` above the end of the kernel is inside heap memory, which means compiled JIT code or a jump through a bad pointer. `nm -n build/ordinal.elf | tail` lists the last symbols, and `_kernel_end` is the end.

The code a quote was compiled to can be examined with `'name xray` in the shell, or with `@dis name` on the host.

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

The pages in `doc/*.md` are linked into the kernel by the Makefile: each file is written to `build/docfs.bin` after a header line `#>> name` where the name is the file name without `.md`. `make doccheck` checks their links. They are read by the pager in `kernel/doc.c`, which handles `#`, `##` and `###` headings, paragraphs, lists, tables, indented code and the links `[text](page)`, `[word](?name)`, `[line](>code)`. The pages are the in-system version of the site's pages ([testing](testing.md) and [source layout](source-layout.md) describe the rest).

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

## Glossary

| Term | Meaning |
|---|---|
| tab | one of the four (`NTABS`) shells. A tab is a `struct task` with its own kernel stack of 256 KiB, key queue, screen buffer, omega world and title. F1 to F4 and Alt-1 to Alt-4 switch between them |
| world | the state of one tab's interpreter: `struct omega`, reached as `W`, which is `current->om`. It holds the current stack and dictionary (`world cur`, a pair of a quote and a `bind` list), the history of 64 earlier worlds, the redo list, the locals and the line history. A `world` value in `omega.h` is the pair that one history step keeps |
| root | the dictionary `root_dict` of words built from the units in `root/*.om`, shared by all tabs. Lookup in a tab's own dictionary comes first and root second. Slot 0 of an installed disk holds its source |
| unit | a named section of root source that begins with the line `#>> name`. A unit is built as one quote and is the part that `'name open` edits. There are at most `NUNITS` 32 units and `UWORDS` 96 words recorded for each |
| quote | the `quote` object: an array of values `V v[n]` with a hit count and optional compiled code. It is both code (`[ 1 2 + ]`) and a list (`[ 1 2 3 ]`) |
| word | a name that runs something. A built-in word is a C function stored in the interned string's `fn` field; a defined word is a `bind` that maps the name to a value, usually a quote |
| symbol | a value of type `T_SYM`, written `'name`: a name used as data, taken by `see`, `help`, `compile`, `xray` and `open` |
| transaction | one line of input. `eval_line` runs it on a copy of the stack and the dictionary and, only when no error was raised, stores the result as the new world and the old one in the history. A failed line changes nothing; effects outside the world (ports, memory, `poke`) are not undone |
| keep stack | `W->keep[256]` with the counter `W->nkeep`: values that the collector treats as live while a C function holds them, pushed with `keep()` and popped with `unkeep(n)` |
| tick | one timer interrupt of the PIT, every 1/`HZ` second, which is 10 ms at `HZ` 100. `ticks()` returns the count since boot |
| slot | a 2048 sector (1 MiB) region of an installed disk that holds one text: slot 0 is root and slots 1 to 4 are the worlds of the four tabs. `persist_load(slot, &len)` reads one |
| ordinal | a transfinite ordinal value (`T_ORD`) in Cantor normal form, up to epsilon0, made with `omega`. The kernel's own name is also ordinal (`KERNEL_NAME`), so the context says which is meant |
| cardinal | a value of type `T_CARD`: the size of a set, `aleph0`, `aleph1`, `continuum`, which has its own arithmetic and the ZFC error for undecidable comparisons |
| pager | the viewer for help pages in `kernel/doc.c`: it lays out a page of the markdown dialect, follows links with Tab, Enter and the mouse and keeps a history for Backspace |
| page | a help page, one file of `doc/*.md` linked into the kernel under its file name. The index of words and the group pages are generated. In `boot/boot.asm` a page is also a 2 MiB mapping |
| group | a word category in `kernel/help.c` (`stack`, `math`, `logic`, `flow`, `lists`, `text`, `io`, `names`, `world`, `infinity`, `memory`, `ports`, `time`, `screen`, `machine`, `dev`, `tools`, `demos`, `games`, `util`, `helpers`, and `syntax`), used by `help`, the index of words and the docs check |
| helper | a word in the `helpers` group: it is used inside other words and is not meant to be typed, but it is a real word and has a help entry (`app-list`, `mb-iter`, `scribble-hint`) |
| app | an entry in the list that `apps` prints, kept as a quote in the unit `apps` (`root/05-apps.om`): a program with a name and a one line description that the user runs by typing its name |
| toy | a program in the root unit `toys` (`root/56-toys.om`): `sieve`, `bounce`, `sorting` and `stars` |
| builtin | a word written in C, registered with `register_words` from a `const struct builtin[]` table |
| `V` | the tagged value of the interpreter: `{ u8 t; i64 n; obj *p; }` with `t` one of `T_NONE`, `T_INT`, `T_STR`, `T_QUOTE`, `T_SYM`, `T_WORD`, `T_DEF`, `T_LOCALS`, `T_SET`, `T_ORD`, `T_CARD`, `T_BIG` |
| pin | a flag (`W->pin`, `obj.pinned`) that keeps objects out of the collector; it is on while root builds |
| compiled | a quote that has run twice and has x86-64 code in `q->jit`; the JIT invalidates it when a word it used is redefined (`jit_version`) |
| host | the Linux build `build/host` of the interpreter, from `test/host.c` |
| qdrive | the QEMU driver `test/qdrive.c` |

## Pull requests

Open a pull request on [GitHub](https://github.com/texivi/Subverge). Describe the change, include the line you tested it with, and make sure `make stress` passes and the docs check prints `0 problems`. A change that adds or alters a word changes the help table and the [all words](all-words.md) page in the same request, and a change that alters behaviour changes the page that describes it.

Keep to the style of the file you are editing: its names, its comment density and its habits. The C is plain C11 with no macros that hide control flow, comments are one to three words, and code does not use anything the freestanding environment lacks.

## Licence

Subverge is released under the [GPL v3](https://www.gnu.org/licenses/gpl-3.0.html). A contribution is released under the same licence.
