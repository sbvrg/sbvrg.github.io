# Interrupts and the timer

Subverge uses three sources of interrupts: CPU exceptions, the timer and the keyboard. Everything else is masked.

## The interrupt table

The kernel fills in 49 entries of the interrupt descriptor table, all as 64-bit interrupt gates in the kernel code segment:

| Vectors | Use |
|---|---|
| 0 to 31 | CPU exceptions |
| 32 to 47 | the sixteen legacy IRQs, after remapping the PICs |
| 48 | `yield`, a software interrupt a tab uses to give up the CPU |

Every entry goes through the same assembly stub. It pushes a dummy error code for the vectors where the CPU doesn't push one, pushes the vector number and all general-purpose registers, and calls one C handler with a pointer to that frame. The handler returns the stack pointer to resume on. Most of the time that is the same frame, but the timer and `yield` can return a different tab's frame, and that is the entire mechanism behind task switching ([scheduler](scheduler.md)).

Because every tab runs in ring 0, the CPU never switches stacks on an interrupt. The frame is pushed onto whatever tab stack was in use, which is why each tab gets its own 256 KiB stack.

## The PICs

At boot the two 8259 PICs are reinitialised so that IRQ 0 to 7 arrive at vectors 32 to 39 and IRQ 8 to 15 at 40 to 47, away from the CPU exceptions. Then every IRQ is masked except IRQ 0, the timer, and IRQ 1, the keyboard.

The disks are driven by polling ([drives](drives.md)), so their IRQs are never used. Nothing else in the machine can interrupt Subverge.

After an IRQ handler returns, the kernel sends an end-of-interrupt to the master PIC, and to the slave as well for IRQ 8 and above.

## The timer

The PIT's channel 0 is programmed in square wave mode with a divisor of 1193182 / 100, giving a tick 100 times a second. `hz` returns 100 and `ticks` returns the number of ticks since boot.

Each tick:

1. adds one to the tick counter;
2. checks whether the interrupted instruction was a `hlt`, and if so counts the tick as idle;
3. once a second, redraws the tab bar and its clock;
4. calls the scheduler, which may switch to another tab.

The idle check works by reading the byte just before the saved instruction pointer. If it is `0xF4`, the CPU was halted in the idle loop when the tick arrived. `top` divides the change in idle ticks by the change in all ticks to show the idle percentage.

`sleep` and `waitkey` are built on the tick counter: a tab records the tick it wants to wake at and yields until that tick has passed.

## The keyboard

IRQ 1 reads one scancode from port `0x60` and turns it into a key for the visible tab. See [keyboard](keyboard.md).

## Exceptions

A CPU exception in a tab doesn't stop the machine. The handler formats a message from the vector, including the faulting address from `cr2` for a page fault, and asks the scheduler to restart the faulting tab from the top of its shell. The tab prints the message and `your last line was dropped`, and its [world](world.md) is unchanged because the line never committed.

The exception names follow the Intel manuals: `divide by zero`, `invalid opcode`, `general protection fault`, `page fault at 0x...` and so on. Integer division by zero in omega fails with an ordinary error before it reaches the CPU, so the exception only appears for code that bypasses the checks, such as a bad `poke` into running code.

If an exception happens while no tab is running, in the idle loop or during boot before the tabs start, it is a kernel panic. The screen turns red, shows the message and the machine halts.

## Counting interrupts

`0 irq` and `1 irq` return how many timer and keyboard interrupts have arrived since boot. `irqmon` shows both live with their rates per second. The other IRQ numbers always return 0, since those lines are masked.

    0 irq .              ticks so far, the same as ticks
    1 irq .              at least two per key, one for press and one for release

## The clock

The time comes from the CMOS real-time clock rather than from the timer. `time` waits until the RTC is not in the middle of an update, then reads seconds, minutes, hours, day, month and year from CMOS registers 0 to 9. It converts from BCD and from 12-hour format when the RTC's status register says they are in use, and adds 2000 to the year.

QEMU's RTC runs in UTC unless it is started with `-rtc base=localtime` ([QEMU](qemu.md)).

## Turning interrupts off

Kernel code that touches state shared between tabs, such as the heap, the screen buffers or the disk controller, disables interrupts for the duration with a save-and-restore of the flags register. A long disk transfer therefore delays the timer, which shows up as a short pause in animations while a large world is being saved.

The only omega word that disables interrupts is `halt`, which also stops the CPU for good.
