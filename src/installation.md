# Installation

Subverge runs in QEMU, either live from the ISO or installed to a disk image.

## Requirements

Running it needs `qemu-system-x86_64` and 256 MB of RAM for the guest. Building it needs gcc, binutils and nasm, and the ISO also needs `grub-mkrescue` and `xorriso`. On Exherbo, QEMU is in the `virtualization` repository:

    # cave resolve -x repository/virtualization
    # cave resolve -x app-virtualization/qemu sys-devel/gcc sys-devel/binutils \
        dev-lang/nasm sys-boot/grub app-cdr/libisoburn

## Getting the ISO

Each release on the [releases page](https://github.com/texivi/Subverge/releases) has `subverge.iso` attached. To build it instead:

    $ git clone https://github.com/texivi/Subverge
    $ cd Subverge
    $ make iso

The ISO is written to `build/subverge.iso`. [Development](development.md) lists the other make targets, and [troubleshooting](troubleshooting.md) covers build failures.

## Booting the live ISO

    $ qemu-system-x86_64 -cdrom build/subverge.iso -m 256M

The ISO is a live system and saves nothing, which makes it a safe place to experiment before installing.

If you end up at a GRUB prompt, `multiboot /boot/subverge.elf` followed by `boot` loads the kernel by hand.

## Installing to a disk image

An installed disk boots with Subverge's own [bootloader](boot.md) and saves your work after every line. Create an image of at least 8 MB and boot the ISO with it attached:

    $ truncate -s 64M disk.img
    $ qemu-system-x86_64 -cdrom build/subverge.iso -boot d -hda disk.img -m 256M

Run `install` at the prompt. It lists the drives, asks for one, and erases it once you type `yes`, so check that the drive it names is your blank image. When it prints `installed`, close QEMU and boot the image on its own:

    $ qemu-system-x86_64 -hda disk.img -m 256M

Anything you defined on the live system is carried over. [Saving](saving.md) describes when the disk is written.

## Disk not found

Subverge only supports IDE, so attach the image with `-hda`. virtio and NVMe disks aren't detected, and `disks` prints `No drives were found.` [QEMU](qemu.md) lists the other flags.

## Next

Continue with [first steps](first-steps.md). The [tour](tour.md) has screenshots of a full install.
