# Boot

The ISO boots with GRUB. Installed disks boot with Subverge's own MBR and second stage, and both paths end in `kmain`.

## From the ISO

The ISO is built with `grub-mkrescue` and a `grub.cfg` that does `multiboot /boot/subverge.elf`. GRUB loads the kernel at 1 MiB, fills in a Multiboot information block, and jumps to `_start` in 32-bit protected mode. GRUB is the only code in the system that wasn't written for Subverge, and it runs only on the ISO.

## From an installed disk

Installed disks don't have GRUB. They have two stages of Subverge's own, written in nasm, in `boot/`.

### The MBR

`boot/mbr.asm` is the 512-byte boot sector at LBA 0. The BIOS loads it at `0x7C00`. It uses the int 13h extensions to read 16 sectors, LBA 1 to 16, to `0x7E00`, and jumps there. If the read fails, it prints `subverge: can't read stage 2` and halts.

### Stage 2

`boot/stage2.asm` does the work GRUB would do, and starts with a header at byte 8:

| Offset | Field |
|---|---|
| 8 | `SUBVERGE`, the magic that marks an installed drive |
| 16 | the kernel's starting LBA |
| 20 | the kernel's length in sectors |
| 24 | the load address, 1 MiB |
| 28 | where bss ends |
| 32 | the entry point |

`install` fills in those fields from the running kernel when it writes stage 2 to the disk, so stage 2 itself never needs to know anything about the kernel. The kernel looks for that same `SUBVERGE` magic to find out which drive it's installed on.

Then stage 2:

1. turns on the A20 line through port `0x92`
2. reads the kernel into low memory in chunks of 64 sectors with int 13h extensions, and prints `subverge: can't read the kernel` if it can't
3. collects the memory map with E820 and the memory size
4. builds a Multiboot information block, with its name as the loader name, `subverge stage2`
5. switches to protected mode, copies the kernel up to 1 MiB, clears bss
6. jumps to the entry point with the Multiboot magic in `eax` and the info block in `ebx`

The kernel can't tell which of the two loaders started it, so the rest of the kernel only ever has to handle one boot protocol.

## _start

`boot/boot.asm` is the kernel's entry, and the first code the kernel runs either way. It has the Multiboot header, and then:

1. sets up a 256 KiB boot stack
2. builds the page tables: one PML4 entry, four PDPT entries, and 2048 page directory entries of 2 MiB each, which identity-maps the first 4 GiB
3. turns on PAE in `cr4`, long mode in the EFER MSR, and paging in `cr0`
4. loads a GDT with one 64-bit code segment and one data segment
5. far-jumps into 64-bit code and calls `kmain` with the Multiboot magic and info pointer

See [internals](internals.md) for what `kmain` does next.

## Why not UEFI

Multiboot and BIOS were enough to boot in QEMU, and the whole system is built on VGA text mode, which UEFI machines often don't have. Graphics mode needs QEMU's display card on top of that. See [hardware](hardware.md) for what that means on real machines. UEFI booting is on the [roadmap](roadmap.md).
