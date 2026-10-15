# Installation

<div class="steps">
<div class="step"><svg viewBox="0 0 48 48"><path d="M24 6v24M15 21l9 9 9-9M8 34v8h32v-8"/></svg><div>
<h3>Get the ISO</h3>
<p>Download <a href="https://github.com/texivi/Subverge/releases/latest/download/subverge.iso">subverge.iso</a> from the latest release, or build it from source.</p>
</div></div>
<div class="step"><svg viewBox="0 0 48 48"><path d="M24 6v16"/><path d="M14 12a15 15 0 1 0 20 0"/></svg><div>
<h3>Boot it live</h3>
<pre><code>$ qemu-system-x86_64 -cdrom subverge.iso -m 256M</code></pre>
</div></div>
<div class="step"><svg viewBox="0 0 48 48"><rect x="7" y="10" width="34" height="28" rx="2"/><path d="M7 28h34M33 33h2"/></svg><div>
<h3>Install to a disk image</h3>
<p>Read the <a href="readme.html">README</a> and the <a href="expectations.html">expectations</a> first, then attach a blank image and run <code>install</code>.</p>
</div></div>
</div>

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

The ISO is written to `build/subverge.iso`. For the other make targets see [development](development.md), and for build failures [troubleshooting](troubleshooting.md).

## Booting the live ISO

    $ qemu-system-x86_64 -cdrom build/subverge.iso -m 256M

The ISO is a live system. Everything you define lives in memory and is gone when QEMU closes, so it is a safe place to try things before installing.

The first screen shows `sys` and a short welcome. The welcome says whether you are on the live ISO or on an installed drive. If it says installed while you meant to boot the ISO, QEMU found an installed image on one of the drives, and the live system has loaded the work saved on it.

`-m 256M` gives the guest 256 MB. The kernel heap takes up to 64 MiB of it, and everything omega allocates comes from the heap ([memory](memory.md)).

If you end up at a GRUB prompt, `multiboot /boot/subverge.elf` followed by `boot` loads the kernel by hand.

## Installing to a disk image

An installed disk boots with Subverge's own [bootloader](boot.md) and saves your work after every line. Create an image of at least 8 MB and boot the ISO with it attached:

    $ truncate -s 64M disk.img
    $ qemu-system-x86_64 -cdrom build/subverge.iso -boot d -hda disk.img -m 256M

Run `install` at the prompt. It lists the drives, asks for one, and erases it once you type `yes`, so check that the drive it names is your blank image. When it prints `installed`, close QEMU and boot the image on its own:

    $ qemu-system-x86_64 -hda disk.img -m 256M

Anything you defined on the live system is carried over. See [saving](saving.md) for when the disk is written.

`install` writes four things to the drive: Subverge's MBR in sector 0, the second stage loader after it, a copy of the running kernel, and the state area that holds root and the four tabs. The image doesn't need a partition table or a filesystem, and any partitions already on it are overwritten. See [disk layout](disk-layout.md) for the exact sectors.

## Upgrading an installed disk

A new release brings a new kernel, and usually a new root as well. Booting the new ISO with an old disk attached runs the new kernel, but the live system finds the installed disk and loads the root and tabs saved on it. That root is the old one, so `sys` still shows the old version and the new root words are missing, even though the built-in words written in C are new.

To put the new kernel on the disk and keep your work, boot the new ISO with the disk attached and run `install` on the same drive. The kernel and bootloader are replaced, and the root and tabs that were loaded are written back.

To get the new root as well, install onto a fresh image instead. Copy your own units across first: `'name src say` prints a unit's source on the old system, and `"name" unit` makes a new unit on the new one ([units](units.md)).

## Removing it

An installed disk image is an ordinary file, so deleting the file removes the system. To reuse the image for something else, overwrite the first sectors, or recreate it with `truncate`. Subverge writes nothing outside the drive it was installed to.

## Disk not found

Subverge only supports IDE, so attach the image with `-hda`, or with `-drive file=disk.img,format=raw,if=ide`. virtio and NVMe disks aren't detected, and `disks` prints `No drives were found.` QEMU's default machine has two IDE channels with two drives each, and Subverge looks at all four. For other flags, see [QEMU](qemu.md).

## Next

Continue with [first steps](first-steps.md).
