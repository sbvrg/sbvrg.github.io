# FAQ

## General

### Is Subverge a Linux distribution?

No. Its kernel, ordinal, was written for Subverge. Subverge is *built* on Linux with gcc and nasm, but it doesn't use any Linux code.

### Is it a TempleOS fork?

No. Subverge borrows a few ideas from TempleOS but none of its code. See [history](history.md).

### Why is it called Subverge?

The name comes from *subvert* and *diverge*. See [history](history.md).

### Can I use it every day?

No. Read the [expectations](expectations.md).

### Is there a roadmap?

No, and there are no release dates either.

## Running it

### Does it run on real hardware?

It is untested. Read [hardware](hardware.md) first, and [report](bugs.md) the result either way.

### Does it run in VirtualBox, VMware or Hyper-V?

They are untested. A virtual machine with IDE disks, a PS/2 keyboard and BIOS booting should work, but only [QEMU](qemu.md) is tested.

### Why can't it see my disk?

Subverge only supports IDE disks. Attach the disk image with `-hda`.

### Where are my files?

Subverge has no files. Your definitions are kept in your tab's [world](world.md), programs are kept in [root](root.md), and an installed disk [saves](saving.md) both.

### Why was my work lost after a reboot?

The live ISO doesn't save anything. [Install](installation.md) Subverge to a disk image to keep your work.

## The system

### Is it POSIX-compliant?

No, and it never will be. Memory, ports and PCI devices are words in omega instead. See [omega for smarties](smarties.md).

### Does it have its own bootloader?

Installed disks use Subverge's own [bootloader](boot.md). The ISO uses GRUB.

### Why does everything run in ring 0?

Separating programs from the kernel would mean building the layer Subverge was written to leave out.

### Is it self-hosting?

No. Subverge is built on Linux.

### Is it multi-user?

No. The user name on the `sys` screen is just a string, and `'user open` changes it.

### Why is the screen so small?

Subverge uses 80 by 25 VGA text mode. See [screen](screen.md).

### Does it have networking, sound or a GUI?

No.

## The language

### Why is the shell a programming language?

So that nothing sits between what you type and the code that runs. See [omega](omega.md).

### Why is everything written backwards?

omega is a postfix language, so you write `2 3 +` instead of `2 + 3`. See [stack](stack.md).

### Why are locals dynamically scoped?

A word can read the locals of the word that called it, which is sometimes useful and sometimes causes surprising bugs. See [names](names.md).

### How big can a number get?

Up to 2^65536, which is about 19,700 digits. For anything bigger, use `omega` ([numbers](numbers.md)).

### Why does omega 1 - fail?

Ordinals only support `+`, `*` and `^`. See [ordinals](ordinals.md).

### Why did my whole line do nothing?

One of its words failed, so the whole line was undone. See [transactions](transactions.md) and [errors](errors.md).

### How do I undo a line?

Type `back`. See [back](back.md).

### How do I stop a program that won't stop?

Press Ctrl-C. If that doesn't work, switch to another [tab](tabs.md), which keeps working.

## The project

### How do I report a bug?

Read [bugs](bugs.md), then use the [issue tracker](https://github.com/texivi/Subverge/issues) or message `texivi` on Discord.

### Can I contribute?

Yes. Read [development](development.md) and [testing](testing.md), then send a pull request.

### What's the license?

The GPL v3. See [license](license.md).
