# Hardware

Subverge is developed and tested in [QEMU](qemu.md) only. It is written for the hardware QEMU emulates, which is the hardware of a PC from the late 1990s with a 64-bit CPU. Many real machines still provide that hardware, often through compatibility modes in the firmware, so Subverge may run on them.

> **Warning:** Every line of omega runs in ring 0 with access to all memory, all I/O ports and every disk the kernel can see. On a real machine, a wrong `poke`, `out` or `install-to` affects real hardware and real data. Use a machine with nothing on it you want to keep.

## What Subverge needs

**An x86-64 CPU.** Any 64-bit Intel or AMD CPU qualifies. Subverge uses one core. The kernel is compiled without SSE, so no particular extensions are required.

**BIOS booting.** The ISO boots through GRUB in BIOS mode, and an installed disk boots through Subverge's own MBR and stage 2, which use BIOS disk services ([boot](boot.md)). Firmware that only boots UEFI can't start it, which includes most recent laptops. Many desktops can still enable a compatibility support module, often called CSM or legacy boot.

**VGA text mode.** All output goes to the 80 by 25 text screen at `0xB8000`, and the kernel reprograms the VGA palette and font registers directly. Most graphics cards still implement text mode when the firmware boots in legacy mode. UEFI-only setups often leave the card in a graphics mode where writes to `0xB8000` show nothing. Graphics mode, started with `gfx`, uses the Bochs display registers of QEMU's standard VGA card.

**A PS/2 keyboard controller.** Keys are read from ports `0x60` and `0x64` ([keyboard](keyboard.md)). Machines without a PS/2 port usually emulate one for USB keyboards when legacy USB support is enabled in the firmware. Without it, Subverge boots and draws its screen but can't be typed at.

**The PIT and the 8259 PICs** for the timer and interrupts. Every PC chipset still emulates these.

**IDE disks**, reached through the legacy ports at `0x1F0` and `0x170` ([drives](drives.md)). SATA controllers in IDE or legacy mode present their disks there. In AHCI mode, which is the usual default, `disks` finds nothing. NVMe and USB disks are never visible. The live ISO doesn't need a disk at all.

**RAM**: 64 MiB or more. The kernel uses at most 64 MiB for its heap and maps the first 4 GiB.

## Trying it

1. Pick a machine whose disks hold nothing you want to keep, or remove the disks.
2. Enable legacy or CSM boot in the firmware, and legacy USB support if the keyboard is USB.
3. Write the ISO to a USB stick:

        # dd if=subverge.iso of=/dev/sdX bs=4M conv=fsync

    replacing `/dev/sdX` with the stick, and double-check that name before pressing Enter.
4. Boot from the stick.
5. Don't run `install`. The live system saves nothing and never writes to a disk unless asked.

Then try a few things: type at the prompt, switch tabs, run `sys`, `top`, `pcils` and `disks`, and leave `mandel` running for a while.

## Reporting the result

Reports from real machines are welcome whether it works or not. Include:

- the machine's make and model, or the mainboard;
- the firmware settings you changed;
- how far it got: GRUB menu, Subverge screen, keyboard working, `disks` output;
- a photograph of the screen if anything went wrong.

Open an [issue](bugs.md) or message `texivi` on Discord.

## Common failures

| What you see | Likely cause |
|---|---|
| the machine skips the USB stick | UEFI-only boot, or the stick wasn't written as a raw image |
| GRUB starts, then a black screen | the graphics card isn't in text mode |
| Subverge's screen appears, keys do nothing | no PS/2 emulation for the USB keyboard |
| `disks` finds nothing | the SATA controller is in AHCI mode |
| a red screen saying `panic` | a fault during boot; photograph it and report it |

## Other virtual machines

VirtualBox set up with an IDE (PIIX) controller and BIOS firmware provides everything Subverge needs and has a reasonable chance of working, and so does VMware with an IDE disk. Hyper-V generation 2 machines are UEFI-only, and generation 1 machines are untested. In any of them, use an IDE disk controller and legacy BIOS firmware.
