# Demo Index

These are arranged in increasing order of difficulty, more or less, and can be used as a tutorial if you start at the top and work down. Click a program to run it, or type its name in a shell.

## Start here

- [first steps](first-steps.md), a short session at the prompt
- tour, the same session typed out for you
- learn, 47 lessons on omega from the stack upwards

## Small tools

- clock shows the time and date
- stopwatch counts hundredths and records laps
- timer counts down from 90 seconds
- calc is an infix calculator
- todo keeps a list
- convert converts units
- password makes passwords
- cal prints the month
- colors draws the sixteen colours
- themes lists the themes

## Games

- snake
- tiles
- pong
- life

## Animations

- rain
- stars
- bounce
- sorting
- sieve
- mandel, which zooms into the Mandelbrot set and shows what the JIT does for a tight loop
- fortune

## Infinity

These act out arguments from Vsauce's video on counting past infinity ([demos](demos.md), [ordinals](ordinals.md), [cardinals](cardinals.md)).

- count counts from 0 past ω and on to ω₁
- ord-demo lists ordinal and cardinal arithmetic as facts
- pairing sets the naturals against the evens
- hotel is Hilbert's hotel with one new guest and then infinitely many buses
- rationals numbers every positive fraction
- ulam draws the primes on a square spiral
- diagonal is Cantor's diagonal argument
- supertask halves a line forever

## Reading the machine

- top shows the CPU, the heap, the shells and the interrupts live
- irqmon counts interrupts as they arrive
- sys prints the system information
- pcils lists the PCI devices
- memls lists the firmware's memory map
- cpuinfo shows what the CPU reports
- disks lists the IDE drives
- hexview edits live memory, starting at the text screen

## Looking inside

Click a line to type it into the first shell.

    'mb-iter see
    'mb-iter xray
    [ -32768 0 2816 40 mandel-at ] bench

`see` prints the source of a word, `xray` the machine code the JIT made for it ([dis](dis.md)), and `bench` times a quote with the JIT off and then on ([jit](jit.md)). `'name open` edits any word in [scrawl](scrawl.md).

The [tools](tools.md), [games](games.md) and [demos](demos.md) pages describe each one.

## Starting a program

A line in this index can be selected and run with Enter. The same names work at the prompt of a shell.
