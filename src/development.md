# Development

Subverge builds on Linux with gcc, binutils and nasm, and the build produces a kernel you can boot in QEMU straight away. See [testing](testing.md) for the tests and [source layout](source-layout.md) for the source tree.

## Source

    $ git clone https://github.com/texivi/Subverge
    $ cd Subverge

## Requirements

| For | You need |
|---|---|
| the kernel | gcc, binutils (`ld`, `objcopy`), nasm |
| running it | `qemu-system-x86_64` |
| the ISO | `grub-mkrescue`, `xorriso`, the BIOS GRUB modules |

On Exherbo, with the `virtualization` repository added:

    # cave resolve -x sys-devel/gcc sys-devel/binutils dev-lang/nasm app-virtualization/qemu \
        sys-boot/grub app-cdr/libisoburn

## Building

    $ make                build/subverge.elf
    $ make run            boot it in QEMU
    $ make iso            build/subverge.iso
    $ make run-iso        boot the ISO in QEMU
    $ make disk           a blank 64M build/disk.img
    $ make run-install    the kernel with that disk attached, for install
    $ make run-disk       boot build/disk.img on its own
    $ make clean          throw build/ away

`make` compiles every file in `kernel/` freestanding, with no standard library, no red zone, no SSE and no stack protector, and links them with `boot/boot.asm`, the root units and the two boot stages into a 64-bit ELF. It is then converted to a 32-bit ELF with `objcopy`, since Multiboot loaders only accept 32-bit ELF, giving `build/subverge.elf`.

Everything in `root/` is concatenated, in file name order, into one blob and linked into the kernel with `ld -r -b binary`. Unit files start with a number to set that order. The MBR and stage 2 are assembled as flat binaries and linked in the same way, so the kernel carries its own bootloader and can write it out during `install`.

`make iso` puts the kernel in an ISO tree with a generated `grub.cfg` and runs `grub-mkrescue` on it.

## Tests

    $ make host           the interpreter as a Linux program
    $ make stress         the same, collecting garbage before every word
    $ make jit-test       boot QEMU and run the JIT test script

See [testing](testing.md) for each of them. Run them before every commit.

## Adding a word

Built-in words live in the `*_words` tables at the bottom of their C files. Root words live in `root/`. Either way the word needs an entry in `kernel/help.c` with its group, stack effect, a description of at most 52 characters and an example, or the docs check fails ([testing](testing.md)).

## Pull requests

Open a pull request on [GitHub](https://github.com/texivi/Subverge). Describe the change, include the line you tested it with, and make sure `make stress` passes and the docs check prints `0 problems`.
