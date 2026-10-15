# Tools

The utility programs in [root](root.md). `q`, Esc or Ctrl-C exits nearly all of them, and `'name see` shows the source of any of them. [Games](games.md) and [demos](demos.md) cover the rest.

## Everyday

**`clock`**, **`stopwatch`** (space marks a lap) and **`90 timer`** (in seconds). In QEMU the clock shows UTC unless configured otherwise ([QEMU](qemu.md)).

**`todo`**, with `"buy milk" todo-add` and `1 todo-done`. The list is a definition called `todo-list` in your tab, so each tab has its own, `back` undoes changes to it, and it is [saved](saving.md) with the world.

**`calc`** is an infix calculator with `+ - * / % ** ( ) & | ^ ~ << >>`, `0x` and `0b` literals, six decimal places and `ans` for the previous result. An empty line exits.

**`255 bases`** prints a number in decimal, hex, octal and binary. **`convert`** lists the unit conversions such as `100 km>mi`. **`password`** prints random passwords, and `12 password-of` makes one of a given length. **`ascii`** and **`colors`** print reference tables.

![clock](images/54-clock.png)

![calc](images/14-calc.png)

## Monitoring

**`top`** shows the tabs, CPU, memory and interrupts live. **`[ ticks . ] watch`** reruns a quote twice a second until a key is pressed, and **`timeit`** times one run. `bench` is described with the [JIT](jit.md).

## Hardware

**`sys`**, **`pcils`**, **`memls`**, **`cpuinfo`** and **`irqmon`** only read, so they are safe to run.

**`hexview`** is not. `0xB8000 hexview` opens a hex editor on live memory, and typing hex digits writes directly to RAM with no undo. It is built on the [memory](memory.md) words.

![hexview](images/13-hexview.png)

**`disks`** and **`install`** are described in [installation](installation.md).
