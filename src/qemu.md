# QEMU

QEMU is the only machine Subverge has run on.

    $ qemu-system-x86_64 -cdrom subverge.iso -m 256M                          live ISO
    $ qemu-system-x86_64 -cdrom subverge.iso -boot d -hda disk.img -m 256M    ready to install
    $ qemu-system-x86_64 -hda disk.img -m 256M                                installed disk
    $ qemu-system-x86_64 -kernel build/subverge.elf -m 256M                   fresh build

## Useful flags

**`-m 256M`** is enough. The kernel heap stops at 64 MB, so more memory goes unused.

**`-hda`** to **`-hdd`** attach disks. Subverge only supports IDE.

**`-boot d`** is needed when a blank disk is attached, otherwise QEMU tries to boot from it.

**`-rtc base=localtime`** sets the clock to local time instead of UTC.

## Flags to avoid

virtio and NVMe disks aren't detected. `-machine q35` changes the disk controller and is untested. `-nographic` shows nothing, since Subverge has no serial console. KVM should work but is untested, so reproduce problems without it before reporting them.

## What Subverge expects

An x86-64 CPU, a Multiboot loader, VGA text mode, a PS/2 keyboard, the PIT and IDE drives. See [hardware](hardware.md) for real machines.

Ctrl-Alt-G releases the keyboard and mouse from the QEMU window.
