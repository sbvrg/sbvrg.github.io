# Hardware

Subverge targets QEMU and hasn't been tested on real machines. If you try one, [report](bugs.md) the result.

## Requirements

- **BIOS booting.** Machines that only boot UEFI, which includes most recent laptops, can't start it.
- **VGA text mode.** Many modern graphics cards barely support it, and UEFI firmware often hides it.
- **A PS/2 keyboard**, or firmware that emulates one for USB keyboards. Without it, Subverge boots but takes no input.
- **IDE drives.** SATA controllers in legacy or IDE mode may work. In AHCI mode, which is the usual default, `disks` finds nothing.

Code in ring 0 has full access to the machine, so on real hardware a mistake can affect real disks.

## Trying it

- Use a machine whose disks you don't care about.
- Boot the ISO from USB in BIOS, legacy or CSM mode.
- Don't install it.
- Photograph the screen and attach it to an [issue](bugs.md).

VirtualBox with its default IDE controller and BIOS firmware has a reasonable chance of working. Recent Hyper-V generations are UEFI only. [QEMU](qemu.md) is the only tested machine.
