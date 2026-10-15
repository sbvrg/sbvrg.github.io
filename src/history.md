# History

## TempleOS

Subverge started from TempleOS. Like TempleOS, its shell is also its compiler, everything runs in ring 0, and one language is used for the whole system.

None of the code came from TempleOS. Its shell is a stack language rather than a C dialect, code is compiled the second time it runs rather than ahead of time, and each line is a [transaction](transactions.md), so a typo in ring 0 doesn't take the system down. It also treats infinity as a value.

## The name

I made up the word **subverge** from *subvert* and *diverge*, after the Latin *sub-*, "under", and *vergere*, "to bend" or "to turn".

> **subverge** (verb): to turn away from an established norm in a way that deliberately undermines it; literally, to dip beneath an edge or surface.
>
> **subvergent** (adjective): quietly, deliberately non-conforming beneath dominant conventions.
>
> **subvergence** (noun): the act of subverging.

The kernel is called **ordinal**, the shell **omega** and the editor **scrawl**.

## Code

All of Subverge was written for it, in C, assembly and omega. The only outside code is GRUB, which boots the ISO.

## Releases

The current release is **Subverge 0.8.0**, with ordinal 0.10.0 and omega 0.9.0. It added integers of any size up to 2^65536.

## License

Subverge has been GPL v3 from the start ([license](license.md)).
