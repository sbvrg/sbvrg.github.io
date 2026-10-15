# dis

The x86-64 disassembler in the kernel, `kernel/dis.c`, behind `xray`, `jitdis`, `dis` and `disr`.

## Using it

    addr n dis          n instructions starting at addr
    addr len disr       every instruction in len bytes from addr
    'fib jitdis         compile fib and disassemble all of it
    'fib xray           fib's source, then its disassembly

`dis` and `disr` take any address at all, not just compiled code. `0x100000 20 dis` disassembles the start of the kernel itself. Point it at data and you get nonsense, since it can't tell code from data.

## What it knows

It decodes the general-purpose integer instruction set: moves, arithmetic, logic, shifts and rotates, `lea`, `imul`, `idiv`, conditional jumps, `set`cc and `cmov`cc, `call`, `ret`, `push` and `pop`, the string instructions, and the system ones the kernel itself uses, like `lgdt`, `lidt`, `invlpg`, `rdmsr`, `wrmsr`, `cpuid`, `rdtsc`, `cli`, `sti`, `hlt` and `iretq`. That covers everything the [JIT](jit.md) generates and everything gcc emits for the kernel, which is compiled with no SSE at all.

It doesn't know SSE, AVX, x87 or anything else exotic. Bytes it can't decode come out as something obviously wrong, rather than something subtly wrong.

## Output

One instruction per line: the address, the bytes, and the instruction in Intel syntax, destination first. Relative jumps and calls are resolved to their absolute targets, so you can follow them by hand with another `dis`.

## How it's checked

`make host` builds the interpreter as a Linux program, and its `@dis name` directive writes a compiled word's raw bytes to `build/dis.bin` and the disassembler's own listing to `build/dis.txt`. Compare the `.txt` with `objdump -D -b binary -m i386:x86-64 -M intel` on the `.bin` to check it. See [testing](testing.md) for the other directives.
