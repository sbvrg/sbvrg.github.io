# dis

Subverge has an x86-64 disassembler in the kernel. It is what `xray` and `jitdis` use to show the code the [JIT](jit.md) produced, and `dis` and `disr` point it at any address you like.

## Using it

    addr n dis          n instructions starting at addr
    addr len disr       every instruction in len bytes from addr
    'fib jitdis         compile fib and disassemble all of it
    'fib xray           fib's source, then its disassembly

`dis` and `disr` take any address, not only compiled code. `0x100000 20 dis` disassembles the first 20 instructions of the kernel itself. The disassembler can't tell code from data, so an address in the middle of a string or a table decodes into instructions that don't mean anything.

`xray` and `jitdis` compile the word first if it hasn't been compiled yet, so you don't need to run it twice beforehand.

## Reading the output

Each line shows one instruction: its address, its bytes in hex, and the instruction in Intel syntax with the destination first. Bytes that don't fit in the column end in `+`. Relative jumps and calls are printed with their absolute target, so you can follow a jump with another `dis` at that address.

Every compiled quote starts the same way. Here is the start of `'sq xray`, for `[ dup * ]`:

    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 0x8
    mov rbp, rsp
    mov rax, 0x42e0a8
    mov rax, qword [rax]
    mov rbx, qword [rax+0x10d0]

The six pushes save the registers the code is about to use, and `sub rsp, 0x8` keeps the CPU stack aligned to 16 bytes for calls back into C. The two loads after `mov rax` find the current tab and then its omega state, which stays in `rbx` while the quote runs. The next few instructions load the stack pointer, the stack depth and the number of bound locals into `r12`, `r14` and `r15`, and check the call depth. See the register table on the [JIT](jit.md) page.

After that comes the code for the words themselves. An inlined `dup` checks the stack depth against `r14`, copies the top 24-byte value cell and adds 24 to `r12`. An inlined `*` checks that both values are plain integers, multiplies them with `imul`, and jumps to the slow path if the overflow flag is set. Words that aren't inlined become a `call` into the interpreter.

The quote ends by writing `r14` and `r15` back to the omega state, undoing the pushes in reverse order, and `ret`.

## What it decodes

It decodes the general-purpose integer instructions: moves, arithmetic, logic, shifts and rotates, `lea`, `imul`, `idiv`, conditional jumps, `set`cc and `cmov`cc, `call`, `ret`, `push` and `pop`, and the string instructions. It also knows the system instructions the kernel uses, such as `lgdt`, `lidt`, `invlpg`, `rdmsr`, `wrmsr`, `cpuid`, `rdtsc`, `cli`, `sti`, `hlt` and `iretq`. That covers everything the JIT generates and everything in the kernel, which is compiled without SSE.

SSE, AVX and x87 instructions aren't decoded. Opcodes it doesn't know are printed as `?`.

## Looking at the kernel

The kernel is loaded at 1 MiB, and `kernel` gives the size of the image. The first 16 bytes at `0x100000` are the Multiboot header, which is data. `_start` follows at `0x100010`, but it starts out as 32-bit code, since GRUB and QEMU enter the kernel in 32-bit protected mode ([boot](boot.md)). The disassembler always decodes 64-bit code, so the first part of `_start` comes out wrong. Everything after the switch to long mode, which is almost all of the kernel, decodes correctly:

    0x100010 40 dis

See [memory](memory.md) for the other fixed addresses.
