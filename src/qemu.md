# QEMU

QEMU is the machine Subverge is developed and tested on. Everything in these docs assumes `qemu-system-x86_64` with its default PC machine, which provides exactly the hardware Subverge drives: BIOS boot, VGA text mode and the Bochs graphics mode of the standard VGA card, a PS/2 keyboard, the PIT timer and IDE disks.

## Command lines

    $ qemu-system-x86_64 -cdrom subverge.iso -m 256M

boots the live ISO. Nothing is saved.

    $ qemu-system-x86_64 -cdrom subverge.iso -boot d -hda disk.img -m 256M

boots the live ISO with a disk image attached, ready for `install`. `-boot d` makes QEMU boot from the CD even though a disk is attached.

    $ qemu-system-x86_64 -hda disk.img -m 256M

boots an installed disk image with Subverge's own bootloader.

    $ qemu-system-x86_64 -kernel build/subverge.elf -m 256M

boots a kernel you built, without an ISO, through QEMU's built-in Multiboot loader. This is what `make run` does ([development](development.md)).

## Disk images

A raw image of at least 8 MiB works:

    $ truncate -s 64M disk.img

`-hda` attaches it as drive 0. `-hdb`, `-hdc` and `-hdd` attach drives 1 to 3, which is the same numbering `disks` and `install` use. The long form, `-drive file=disk.img,format=raw,if=ide`, does the same as `-hda` and avoids QEMU's warning about guessing the format.

Subverge reads and writes the image directly with no filesystem, so don't mount it or let another program write to it while QEMU is running.

## Memory

`-m 256M` is enough for anything Subverge does. The kernel heap is at most 64 MiB, and memory beyond that is reported by `memmap` and `kernel` but otherwise unused. With less RAM the heap shrinks to fit, and large bignums and big worlds run out of memory sooner. The page tables map the first 4 GiB, so memory above that can't be reached.

## The clock

QEMU's real-time clock runs in UTC by default, so the clock in the tab bar and `time` show UTC. Add

    -rtc base=localtime

to see local time.

## Flags that cause trouble

- **virtio, NVMe, AHCI, SCSI or USB disks** (`if=virtio`, `-device nvme`, `-device ahci`) aren't detected, and `install` finds no drives. Use `-hda` or `if=ide`.
- **A `-vga` other than `std`** has no Bochs display registers, so `gfx` fails. `std` is the default.
- **`-machine q35`** puts the disks on an AHCI controller. Use the default `pc` machine.
- **`-nographic` and `-display none`** hide the only output Subverge has, since it writes to the VGA screen and not to a serial port.
- **UEFI firmware** such as OVMF can't boot Subverge ([boot](boot.md)).
- **`-enable-kvm`** should work but is untested. Reproduce a problem without KVM before reporting it.

## Keyboard and mouse

Click into the QEMU window to give it the keyboard. Ctrl-Alt-G releases the keyboard and mouse again. F1 to F4 switch Subverge's tabs, and the keys that QEMU itself grabs, such as Ctrl-Alt-1 and Ctrl-Alt-2 for its monitor, never reach Subverge.

Subverge uses a US layout. On other host layouts some symbols are on different keys than printed, since QEMU passes on key positions.

## Screenshots

The QEMU monitor's `screendump file.ppm` command saves the screen exactly as Subverge drew it. Attach one to [bug reports](bugs.md).

## Other emulators

Bochs, VirtualBox and VMware provide similar hardware and may work with an IDE controller and BIOS firmware, but only QEMU is tested. For real machines, see [hardware](hardware.md).
