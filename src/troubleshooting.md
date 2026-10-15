# Troubleshooting

## Building

**`nasm: No such file or directory`.** Install nasm ([development](development.md)).

**`grub-mkrescue: command not found`.** It comes with `sys-boot/grub`, and it needs `app-cdr/libisoburn` for `xorriso`.

**QEMU says the ISO isn't bootable.** Only the EFI GRUB modules are installed. Install the BIOS ones and rebuild.

**The docs check prints problems.** A word's help entry is missing or wrong ([testing](testing.md)).

## Booting

**Black screen or "No bootable device".** A blank disk is attached and QEMU is booting from it. Add `-boot d`.

**A GRUB prompt.** `multiboot /boot/subverge.elf`, then `boot`.

**The installed disk won't boot.** Boot it with `-hda`, and check that `install` actually said `installed`.

**`the saved root didn't build, using the built-in one`.** Usually an old disk on a new kernel. See [root](root.md).

## Using it

**The clock is wrong.** It's UTC. Add `-rtc base=localtime`.

**`No drives were found.`** Use `-hda`, not virtio or NVMe.

**Nothing is saved.** You're on the live ISO ([installation](installation.md)).

**My whole line did nothing.** Something on it failed. Read the red text ([transactions](transactions.md)).

**`back` went too far.** It skips lines that changed nothing ([back](back.md)).

**A word works at the prompt but not inside another word.** Dynamic scoping ([names](names.md)).

**`forget` says it isn't defined in this tab.** It only removes your own definitions ([names](names.md)).

**My root edit didn't do anything.** It didn't build. Open it again and read the error ([root](root.md)).

**I used `edit` on `top` and the other tabs didn't change.** You made a private copy. Use `open` ([scrawl](scrawl.md)).

**My program isn't in `apps`.** It's never automatic ([apps](apps.md)).

**Ctrl-C doesn't stop it.** Switch tabs ([tabs](tabs.md)).

**Everything froze.** Something wrote over memory the kernel needs, or `halt` was run. Close QEMU. An installed disk was saved after every line.

## Still broken

See [bugs](bugs.md) for how to report it.
