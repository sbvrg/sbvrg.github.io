# All words

These are the words `help` lists, grouped as `help` groups them. In each stack effect the top of the stack is on the right.

## syntax

How code is written.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `[ ]` | `-- q` | A quote: code or a list, not run yet. | `[ 1 2 + ]` |
| `:name` | `q --` | Defines a word from the top value. | `[ dup * ] :sq` |
| `->name` | `v --` | Sets a local name inside a quote. | `5 ->x   x x +` |
| `{ a b }` | `a b --` | Takes values off the stack as locals. | `[ { a b } a b - ] :diff` |
| `'name` | `-- 'name` | A symbol: a name used as a value. | `'sq see` |
| `"text"` | `-- s` | A string. Escapes: \n \t \e \w \A. | `"hi\n" write` |
| `42 0x2a` | `-- n` | Whole numbers of any size, decimal or hex. | `2 100 ^` |
| `#` |  | A comment to the end of the line. | `1 2 + # three` |

## stack

Move values around.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `dup` | `a -- a a` | Copies the top value. | `3 dup *   gives 9` |
| `drop` | `a --` | Throws the top value away. | `1 2 drop   leaves 1` |
| `swap` | `a b -- b a` | Swaps the top two values. | `1 2 swap   leaves 2 1` |
| `over` | `a b -- a b a` | Copies the second value to the top. | `1 2 over   leaves 1 2 1` |
| `rot` | `a b c -- b c a` | Moves the third value to the top. | `1 2 3 rot   leaves 2 3 1` |
| `nip` | `a b -- b` | Drops the second value. | `1 2 nip   leaves 2` |
| `depth` | `-- n` | How many values are on the stack. | `1 2 depth   leaves 1 2 2` |
| `empty` | `...  --` | Clears the whole stack. | `1 2 3 empty` |
| `pick` | `... n -- ... x` | Copies the value n below the top. | `1 2 3 2 pick   gives 1` |
| `tuck` | `a b -- b a b` | Copies the top under the second. | `1 2 tuck   leaves 2 1 2` |
| `2dup` | `a b -- a b a b` | Copies the top two values. | `1 2 2dup   leaves 1 2 1 2` |

## math

Arithmetic.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `+` | `a b -- c` | Adds. Also works on ordinals and cardinals. | `2 3 +   gives 5` |
| `-` | `a b -- c` | Subtracts. Whole numbers only. | `5 2 -   gives 3` |
| `*` | `a b -- c` | Multiplies. | `6 7 *   gives 42` |
| `/` | `a b -- c` | Divides, rounding toward zero. | `7 2 /   gives 3` |
| `mod` | `a b -- r` | The remainder after dividing. | `7 3 mod   gives 1` |
| `^` | `a b -- c` | Raises a to the power b, exactly. | `2 100 ^   all 31 digits` |
| `neg` | `a -- -a` | Flips the sign. | `5 neg   gives -5` |
| `abs` | `a -- b` | Drops the sign. | `-5 abs   gives 5` |
| `min` | `a b -- c` | The smaller of two numbers. | `3 9 min   gives 3` |
| `max` | `a b -- c` | The bigger of two numbers. | `3 9 max   gives 9` |
| `sqrt` | `n -- r` | The square root, rounded down. | `99 sqrt   gives 9` |
| `gcd` | `a b -- c` | The greatest common divisor. | `12 18 gcd   gives 6` |

## logic

Comparisons and bit operations.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `=` | <code>a b -- 1&#124;0</code> | 1 if equal, otherwise 0. Works on strings. | `3 3 =   gives 1` |
| `<` | <code>a b -- 1&#124;0</code> | 1 if a is less than b. | `1 2 <   gives 1` |
| `>` | <code>a b -- 1&#124;0</code> | 1 if a is greater than b. | `1 2 >   gives 0` |
| `<=` | <code>a b -- 1&#124;0</code> | 1 if a is less than or equal to b. | `2 2 <=   gives 1` |
| `>=` | <code>a b -- 1&#124;0</code> | 1 if a is greater than or equal to b. | `2 3 >=   gives 0` |
| `and` | <code>a b -- 1&#124;0</code> | 1 if both are non-zero. | `1 0 and   gives 0` |
| `or` | <code>a b -- 1&#124;0</code> | 1 if either is non-zero. | `1 0 or   gives 1` |
| `not` | <code>a -- 1&#124;0</code> | 1 if a is zero, otherwise 0. | `0 not   gives 1` |
| `&` | `a b -- c` | Bitwise and. | `12 10 &   gives 8` |
| <code>&#124;</code> | `a b -- c` | Bitwise or. | <code>12 10 &#124;   gives 14</code> |
| `xor` | `a b -- c` | Bitwise exclusive or. | `12 10 xor   gives 6` |
| `~` | `a -- b` | Flips every bit. | `0 ~   gives -1` |
| `<<` | `a b -- c` | Shifts a left by b bits. | `1 4 <<   gives 16` |
| `>>` | `a b -- c` | Shifts a right by b bits. | `256 4 >>   gives 16` |

## flow

Choices and loops.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `do` | `q --` | Runs a quote. | `[ 1 2 + ] do   gives 3` |
| `if` | `c t f --` | Runs t if c is non-zero, otherwise f. | `1 [ "yes" ] [ "no" ] if` |
| `when` | `c q --` | Runs q if c is non-zero. | `5 0 > [ "positive" say ] when` |
| `unless` | `c q --` | Runs q if c is zero. | `0 [ "zero" say ] unless` |
| `times` | `n q --` | Runs q n times. | `3 [ "hi" say ] times` |
| `for` | `a b q --` | Runs q for i from a to b-1, i on the stack. | `0 3 [ . ] for   prints 0 1 2` |
| `while` | `c q --` | Runs c, and while it gives non-zero, q. | `0 [ dup 3 < ] [ 1 + ] while   leaves 3` |
| `each` | `l q --` | Runs q on each item of a list or string. | `[ 1 2 3 ] [ . ] each` |
| `map` | `l q -- list` | A new list: q run on each item. | `[ 1 2 3 ] [ 2 * ] map   gives [ 2 4 6 ]` |
| `filter` | `l q -- list` | Keeps the items where q gives non-zero. | `[ 1 2 3 4 ] [ 2 mod 0 = ] filter   gives [ 2 4 ]` |
| `eval` | `s --` | Runs a string as code. | `"1 2 +" eval   gives 3` |
| `trace` | `q --` | Runs q a word at a time, showing the stack. | `[ 1 2 + ] trace` |
| `try` | <code>q -- 1&#124;0</code> | Runs q. Leaves 0 and prints the error if it fails. | `[ 1 0 / ] try` |
| `fail` | `s --` | Fails the line with s as the error. | `"too big" fail` |

## lists

Lists, which are also quotes.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `list` | `... n -- l` | Packs the top n values into a list. | `1 2 3 3 list   gives [ 1 2 3 ]` |
| `range` | `a b -- l` | The numbers from a up to b-1. | `0 4 range   gives [ 0 1 2 3 ]` |
| `append` | `l x -- list` | A new list with x on the end. | `[ 1 2 ] 3 append   gives [ 1 2 3 ]` |
| `cat` | `a b -- c` | Joins two lists or two strings. | `[ 1 ] [ 2 ] cat   gives [ 1 2 ]` |
| `len` | `l -- n` | How long a list or string is. | `"hello" len   gives 5` |
| `type` | `x -- s` | The kind of value x is, such as list or string. | `[ 1 ] type   gives "list"` |
| `at` | `l i -- x` | Item i of a list or string, from 0. | `[ 5 6 7 ] 1 at   gives 6` |
| `first` | `l -- x` | The first item. | `[ 5 6 7 ] first   gives 5` |
| `last` | `l -- x` | The last item. | `[ 5 6 7 ] last   gives 7` |
| `rest` | `l -- list` | Everything except the first item. | `[ 5 6 7 ] rest   gives [ 6 7 ]` |
| `has` | <code>l x -- 1&#124;0</code> | 1 if the list contains x. | `[ 5 6 ] 6 has   gives 1` |
| `spread` | `l -- ...` | Puts every item of the list on the stack. | `[ 1 2 3 ] spread   leaves 1 2 3` |
| `index` | `l x -- i` | Where x is in the list, or -1. | `[ 5 6 7 ] 6 index   gives 1` |
| `reverse` | `l -- list` | A list or string back to front. | `[ 1 2 3 ] reverse` |
| `sort` | `l -- list` | Sorts numbers or strings, smallest first. | `[ 3 1 2 ] sort   gives [ 1 2 3 ]` |
| `sum` | `l -- n` | Adds up a list of numbers. | `[ 1 2 3 ] sum   gives 6` |
| `fold` | `l x q -- y` | Runs q on x and each item in turn. | `[ 1 2 3 ] 1 [ * ] fold   gives 6` |

## text

Strings.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `str` | `v -- s` | Turns any value into a string. | `42 str   gives "42"` |
| `hex` | `n -- s` | A number in hex, without the 0x. | `255 hex   gives "ff"` |
| `chr` | `n -- s` | The character with that code. | `65 chr   gives "A"` |
| `slice` | `s a n -- str` | n characters of s, starting at a. | `"hello" 1 3 slice   gives "ell"` |
| `pad` | `s n -- str` | Pads with spaces to n wide. Negative pads left. | `"7" -3 pad   gives "  7"` |
| `find` | `s sub -- i` | Where sub first appears in s, or -1. | `"hello" "ll" find   gives 2` |
| `split` | `s sep -- l` | Cuts s into a list at each sep. | `"a,b" "," split   gives [ "a" "b" ]` |
| `>num` | `s -- n` | Reads a number from a string. | `"42" >num   gives 42` |
| `upper` | `s -- str` | Turns letters into capitals. | `"hi" upper   gives "HI"` |
| `lower` | `s -- str` | Turns capitals into small letters. | `"Hi" lower   gives "hi"` |
| `trim` | `s -- str` | Drops spaces and newlines at both ends. | `" hi " trim   gives "hi"` |
| `starts?` | <code>s pre -- 1&#124;0</code> | 1 if s begins with pre. | `"hello" "he" starts?   gives 1` |
| `ends?` | <code>s suf -- 1&#124;0</code> | 1 if s ends with suf. | `"hello" "lo" ends?   gives 1` |
| `replace` | `s a b -- str` | Replaces every a in s with b. | `"a-b" "-" "+" replace` |
| `join` | `l sep -- s` | Joins a list into one string with sep between. | `[ 1 2 ] ", " join   gives "1, 2"` |

## io

Printing and keys.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `.` | `v --` | Prints a value as code, then a new line. | `"hi" .   prints "hi"` |
| `say` | `v --` | Prints a value, then a new line. | `"hi" say   prints hi` |
| `write` | `v --` | Prints a value with no new line. | `"a" write "b" say   prints ab` |
| `emit` | `n --` | Prints the character with that code. | `65 emit   prints A` |
| `nl` | `--` | Starts a new line. | `nl` |
| `color` | `n --` | Sets the text colour, 0 to 15. | `14 color "yellow" say` |
| `key` | `-- n` | Waits for a key and gives its code. | `key   then press a key` |
| `key?` | `-- n` | The key pressed, or -1. Doesn't wait. | `key?` |
| `waitkey` | `ticks -- n` | Waits up to that many ticks for a key. | `50 waitkey   half a second, -1 if none` |
| `ask` | `s -- str` | Prints a prompt and reads a line. | `"name? " ask` |

## names

Definitions.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `get` | `'x -- v` | Pushes what a name is defined as. | `'sq get   gives [ dup * ]` |
| `forget` | `'x --` | Removes a definition from this tab. | `'sq forget` |
| `>sym` | `s -- 'x` | Makes a symbol from a string. | `"sq" >sym get` |
| `defined?` | <code>&#x27;x -- 1&#124;0</code> | 1 if the name is defined or built in. | `'dup defined?   gives 1` |
| `see` | `'x --` | Shows how a name is defined. | `'sq see` |
| `words` | `--` | Lists everything defined in this tab. | `words` |
| `edit` | `'x --` | Opens a name in the editor. Saving redefines it. | `'sq edit` |

## world

History, saving and root.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `help` | `'x --` | Explains a word or a group. Alone, lists all. | `'dup help   or just   help` |
| `back` | `--` | Undoes the last line, up to 64 lines. | `back` |
| `stats` | `-- a b c d e` | Objects, collections, names, stack, history. | `stats` |
| `save` | `--` | Saves root and every tab to the drive now. | `save` |
| `home` | `-- n` | The drive Subverge lives on, or -1. | `home` |
| `root` | `--` | Lists the root units and the words in each. | `root` |
| `open` | `'x --` | Edits the root unit that defines x. | `'top open` |
| `unit` | `s --` | Makes a new root unit and opens it. | `"mine" unit` |
| `src` | `'x -- s` | The source of the root unit that defines x. | `'top src` |
| `welcome` | `--` | The intro screen shown at startup. | `welcome` |
| `redo` | `--` | Takes back a back. | `back redo` |
| `apropos` | `s --` | Lists every word whose help mentions s. | `"string" apropos` |

## infinity

Ordinals and cardinals.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `omega` | `-- w` | The first infinite ordinal. | `omega 1 +   gives w+1` |
| `epsilon0` | `-- e` | The first ordinal where omega^x = x. | `omega epsilon0 ^ epsilon0 =   gives 1` |
| `omega1` | `-- w1` | The first uncountable ordinal. | `omega1 card   gives aleph1` |
| `aleph0` | `-- c` | The size of the natural numbers. | `aleph0 aleph0 +   gives aleph0` |
| `aleph1` | `-- c` | The next size of infinity up. | `aleph0 aleph1 <   gives 1` |
| `aleph` | `n -- c` | The nth aleph. | `2 aleph` |
| `continuum` | `-- c` | The size of the real numbers, 2^aleph0. | `aleph1 continuum <=   gives 1` |
| `card` | `o -- c` | The size of an ordinal. | `omega 2 * card   gives aleph0` |
| `ordinal?` | <code>v -- 1&#124;0</code> | 1 if the value is an ordinal. | `omega ordinal?   gives 1` |

## memory

Raw memory.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `peek` | `addr -- n` | Reads one byte of memory. | `0xB8000 peek` |
| `poke` | `n addr --` | Writes one byte of memory. | `65 0xB8000 poke` |
| `peekd` | `addr -- n` | Reads 4 bytes of memory. | `0xB8000 peekd` |
| `poked` | `n addr --` | Writes 4 bytes of memory. | `0 0xB8000 poked` |
| `peekq` | `addr -- n` | Reads 8 bytes of memory. | `0xB8000 peekq` |
| `pokeq` | `n addr --` | Writes 8 bytes of memory. | `0 0xB8000 pokeq` |
| `alloc` | `n -- addr` | Gets n bytes of zeroed memory, up to 16M. | `64 alloc` |
| `free` | `addr --` | Gives alloc memory back. | `64 alloc free` |
| `heap` | `-- used total` | Bytes of heap in use, and in total. | `heap` |

## ports

Ports, cpu and pci.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `in` | `port -- n` | Reads a byte from an I/O port. | `0x64 in` |
| `out` | `n port --` | Writes a byte to an I/O port. | `0 0x80 out` |
| `ind` | `port -- n` | Reads 4 bytes from an I/O port. | `0xCFC ind` |
| `outd` | `n port --` | Writes 4 bytes to an I/O port. | `0 0x80 outd` |
| `pci` | `-- l` | PCI devices: [ bus dev fn vendor dev class sub ] | `pci len` |
| `pci@` | `b d f off -- n` | Reads 4 bytes of a device's PCI config. | `0 0 0 0 pci@` |
| `cpuid` | `leaf -- a b c d` | Runs cpuid and gives eax ebx ecx edx. | `0 cpuid` |
| `cpu` | `-- s` | The CPU's name. | `cpu say` |
| `cr` | `n -- v` | Reads control register 0, 2, 3 or 4. | `0 cr` |
| `rdtsc` | `-- n` | The CPU's cycle counter. | `rdtsc` |
| `irq` | `n -- count` | How many times interrupt n has fired. | `1 irq   the keyboard` |

## time

Clocks and counters.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `ticks` | `-- n` | Timer ticks since boot, 100 a second. | `ticks` |
| `hz` | `-- n` | Ticks per second. | `hz` |
| `time` | `-- y mo d h m s` | The clock: year month day hour minute second. | `time` |
| `idle` | `-- n` | Ticks the CPU spent idle. | `idle` |
| `sleep` | `ticks --` | Waits that long. Ctrl-C stops it. | `100 sleep   waits one second` |
| `beep` | `hz ticks --` | Plays a tone on the PC speaker. Ctrl-C stops it. | `440 50 beep   plays A for half a second` |
| `rand` | `n -- r` | A random number from 0 to n-1. | `6 rand` |

## screen

Drawing on the screen.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `put` | `ch x y color --` | Puts one character on the screen. | `42 10 5 14 put` |
| `text` | `s x y color --` | Writes a string at a position, in graphics mode too. | `"hi" 10 5 14 text` |
| `screen@` | `x y -- ch color` | Reads the character and colour there. | `10 5 screen@` |
| `wipe` | `--` | Clears the screen. | `wipe` |
| `cursor` | `x y --` | Moves the cursor. | `0 0 cursor` |
| `nocursor` | `--` | Hides the cursor. | `nocursor` |
| `where` | `-- x y` | Where the cursor is. | `where` |
| `size` | `-- w h` | The screen size: 80 by 24. | `size` |
| `gfx` | `--` | Starts 640 by 480 graphics. A tab key leaves it. | `gfx` |
| `gfx-off` | `--` | Back to the text screen. | `gfx-off` |
| `dot` | `x y col --` | Sets one pixel in graphics mode. | `320 240 14 dot` |
| `box` | `x y w h col --` | Fills a rectangle in graphics mode. | `20 20 100 60 5 box` |
| `window` | `x y w h title --` | Draws a titled window frame in graphics mode. | `40 40 300 160 "first" window` |
| `title` | `s --` | Names this tab in the tab bar. | `"build" title` |
| `tab` | `n -- l` | About tab n: [ title state active ]. | `2 tab` |
| `mytab` | `-- n` | Which tab you are in, 1 to 4. | `mytab` |
| `theme` | `'x --` | Switches to a colour theme, and remembers it. | `'raw theme` |
| `themes` | `--` | Lists the themes and shows the colours. | `themes` |
| `theme@` | `-- s` | The name of the current theme. | `theme@ say` |
| `logo` | `'x --` | Sets the logo sys draws, and remembers it. | `'haelide logo` |
| `logos` | `--` | Lists the logos. | `logos` |
| `logo@` | `-- s` | The name of the current logo. | `logo@ say` |
| `mouse` | `-- x y buttons` | Where the pointer is, and 1 left, 2 right, 4 middle. | `mouse` |
| `mouse?` | `-- 1|0` | 1 when a mouse was found. | `mouse?` |
| `doc` | `s --` | Opens a help page. Q leaves. | `"prompt" doc` |
| `docs` | `--` | Opens the index of help pages. | `docs` |
| `rgb` | `n r g b --` | Sets colour n to red, green, blue 0 to 255. | `14 255 0 0 rgb` |

## machine

Hardware and drives.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `memmap` | `-- l` | The memory map: [ base length type ]. | `memmap len` |
| `kernel` | `-- k m` | Kernel image bytes, and bytes of RAM. | `kernel` |
| `sys-c` | `--` | The system info screen written in C. | `sys-c` |
| `reboot` | `--` | Restarts the machine. | `reboot` |
| `halt` | `--` | Stops the CPU. Only a reset gets out. | `halt` |
| `drives` | `-- l` | Every disk: [ n model megabytes home ]. | `drives len` |
| `disks` | `--` | Lists the disks. | `disks` |
| `install` | `--` | Installs Subverge on a drive you pick. | `install   erases that drive` |
| `install-to` | `n --` | Installs on drive n without asking. | `0 install-to   erases drive 0` |

## dev

The jit and the disassembler.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `jit` | `--` | Shows if the jit is on and what it compiled. | `jit` |
| `jit-on` | `--` | Turns the jit on. | `jit-on` |
| `jit-off` | `--` | Turns the jit off, so only the interpreter runs. | `jit-off` |
| `compile` | `'x -- addr len` | Compiles a word now. Gives its code address, size. | `'sq compile` |
| `addr` | `'x -- addr` | The address of a word's compiled code. | `'sq addr` |
| `dis` | `addr n --` | Disassembles n instructions at an address. | `'sq addr 10 dis` |
| `disr` | `addr bytes --` | Disassembles a range of bytes. | `'sq compile disr` |
| `jitdis` | `'x --` | Compiles a word and disassembles all of it. | `'sq jitdis` |
| `xray` | `'x --` | A word's source, then its machine code. | `'sq xray` |
| `bench` | `q --` | Times q interpreted, then compiled. | `[ 1000000 [ 1 + ] times ] bench` |

## tools

Ready-made utilities.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `learn` | `--` | A guided tour of the language. Space goes on. | `learn` |
| `lesson` | `n --` | Starts learn at lesson n, counting from 0. | `28 lesson` |
| `apps` | `--` | Lists the programs you can run. | `apps` |
| `sys` | `--` | The logo and system info. | `sys` |
| `top` | `--` | Live tabs, memory and interrupts. q leaves. | `top` |
| `watch` | `q --` | Runs q twice a second until a key. | `[ ticks . ] watch` |
| `timeit` | `q --` | Runs q and says how long it took. | `[ 1000 [ ] times ] timeit` |
| `hexview` | `addr --` | Hex editor on live memory. q leaves. | `0xB8000 hexview` |
| `pcils` | `--` | Lists the PCI devices. | `pcils` |
| `memls` | `--` | Lists the memory map. | `memls` |
| `cpuinfo` | `--` | What the CPU says about itself. | `cpuinfo` |
| `irqmon` | `--` | Live interrupt counts. q leaves. | `irqmon` |
| `calc` | `--` | A calculator. An empty line leaves. | `calc` |
| `clock` | `--` | A live clock. q leaves. | `clock` |
| `stopwatch` | `--` | Counts up. Space marks a lap, q leaves. | `stopwatch` |
| `timer` | `seconds --` | Counts down, then says the time is up. | `90 timer` |
| `todo` | `--` | Shows your to-do list. | `todo` |
| `todo-add` | `s --` | Adds an item to the to-do list. | `"buy milk" todo-add` |
| `todo-done` | `n --` | Removes item n from the to-do list. | `1 todo-done` |
| `bases` | `n --` | Shows n in decimal, hex, octal and binary. | `255 bases` |
| `ascii` | `--` | A table of the printable characters. | `ascii` |
| `colors` | `--` | The 16 colours and their numbers. | `colors` |
| `convert` | `--` | Lists the unit conversions. | `convert` |
| `password` | `--` | Prints five random passwords. | `password` |
| `km>mi` | `n -- s` | Kilometres to miles, as text. | `100 km>mi   gives "62.13"` |
| `mi>km` | `n -- s` | Miles to kilometres, as text. | `100 mi>km   gives "160.93"` |
| `kg>lb` | `n -- s` | Kilograms to pounds, as text. | `10 kg>lb   gives "22.04"` |
| `lb>kg` | `n -- s` | Pounds to kilograms, as text. | `10 lb>kg   gives "4.53"` |
| `c>f` | `n -- s` | Celsius to Fahrenheit, as text. | `37 c>f   gives "98.60"` |
| `f>c` | `n -- s` | Fahrenheit to Celsius, as text. | `98 f>c   gives "36.66"` |
| `cal` | `--` | This month, with today marked. | `cal` |
| `month` | `y m --` | The calendar for any month. | `2026 12 month` |
| `date` | `-- s` | Today as year-month-day. | `date say` |

## demos

Math demos.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `count` | `--` | Counts from 0 past every finite number. | `count` |
| `ord-demo` | `--` | Ordinal and cardinal arithmetic, live. | `ord-demo` |
| `powerset` | `l -- list` | Every subset of a list. | `[ 1 2 ] powerset` |
| `pairing` | `--` | The naturals and the evens match up. | `pairing` |
| `hotel` | `--` | A full hotel takes guests, then infinite buses. | `hotel` |
| `rationals` | `--` | Every positive fraction gets a number. | `rationals` |
| `pair` | `a b -- n` | Cantor pairing: two numbers into one number. | `3 4 pair` |
| `unpair` | `n -- a b` | Undoes pair. | `32 unpair` |
| `fusc` | `n -- f` | Stern's diatomic sequence. | `5 fusc` |
| `rational` | `n -- p q` | The n-th positive fraction in Calkin-Wilf order. | `7 rational` |
| `collatz` | `n -- steps` | Steps for n to reach 1 by halving or 3n+1. | `27 collatz` |
| `thue` | `n -- bit` | Parity of the 1 bits of n. | `0 16 range [ thue ] map` |
| `prime?` | `n -- flag` | 1 when n is prime. | `97 prime?` |
| `ulam` | `--` | Primes laid out on a square spiral. | `ulam` |
| `diagonal` | `--` | Cantor's proof the reals can't be listed. | `diagonal` |
| `supertask` | `--` | Halve a line forever, in finite time. | `supertask` |
| `mandel` | `--` | The Mandelbrot set, zooming in. Any key goes on. | `mandel` |
| `mandel-at` | `ox oy sc mx --` | Draws one view of the set. 65536 means 1.0. | `-32768 0 2816 40 mandel-at` |

## games

Games and toys.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `snake` | `--` | Arrow keys steer, q quits. | `snake` |
| `scribble` | `--` | Draws with the mouse. Q leaves. | `scribble` |
| `life` | `--` | Conway's Game of Life on raw memory. | `life` |
| `rain` | `--` | A screensaver. Any key leaves. | `rain` |
| `fortune` | `--` | Prints one short fact. | `fortune` |
| `sieve` | `--` | The sieve of Eratosthenes, drawn live. | `sieve` |
| `bounce` | `--` | Balls bouncing and leaving trails. | `bounce` |
| `sorting` | `--` | Bubble sort drawn as bars. | `sorting` |
| `stars` | `--` | Flying through a starfield. | `stars` |
| `pong` | `--` | Left and right move the paddle, q quits. | `pong` |
| `tiles` | `--` | Slide and merge numbered tiles. | `tiles` |

## util

Small helpers.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `sq` | `n -- n2` | Squares a number. | `7 sq   gives 49` |
| `inc` | `n -- n+1` | Adds one. | `7 inc   gives 8` |
| `dec` | `n -- n-1` | Subtracts one. | `7 dec   gives 6` |
| `kb` | `n -- s` | Bytes as a string of K. | `2048 kb   gives "2K"` |
| `mb` | `n -- s` | Bytes as a string of M. | `2097152 mb   gives "2M"` |
| `uptime` | `-- s` | How long since boot. | `uptime say` |
| `>hex` | `n -- s` | A number as a string like 0xff. | `255 >hex   gives "0xff"` |
| `fmt` | `v n -- s` | A value padded to n columns. | `42 6 fmt   gives "42    "` |
| `attr` | `fg bg -- n` | A colour byte for put and text. | `14 1 attr` |
| `fill` | `ch x y n c --` | Draws a row of one character. | `42 0 5 20 14 fill` |
| `bar` | `x y w pct c --` | Draws a meter that is pct percent full. | `2 5 20 60 10 bar` |
| `header` | `s --` | Draws a title bar across the top. | `"hi" header` |
| `quit-key?` | <code>k -- 1&#124;0</code> | 1 if k is q, Esc or Ctrl-C. | `113 quit-key?   gives 1` |

## helpers

Words the utilities use inside.

| Word | Effect | What it does | Example |
|---|---|---|---|
| `lessons` | `-- list` | The lessons that learn walks through. | `lessons len` |
| `scribble-hint` | `--` | Prints the keys line of scribble. |  |
| `app-list` | `-- list` | The programs that apps lists. | `app-list len` |
| `app-cell` | `e w --` | Prints one entry of apps. |  |
| `mb-iter` | `cx cy mx -- n` | Steps a point until it escapes, up to mx steps. | `0 0 40 mb-iter   gives 40` |
| `two` | `n -- s` | A number as at least two digits. | `7 two   gives "07"` |
| `hms` | `time -- s` | The time part of time as hh:mm:ss. | `time hms` |
| `mmss` | `ticks -- s` | Ticks as mm:ss.cc. | `6150 mmss   gives "01:01.50"` |
| `todo-get` | `-- list` | The to-do list. | `todo-get` |
| `to-base` | `n b -- s` | n written in base b. | `255 16 to-base   gives "ff"` |
| `base-row` | `label v --` | Prints one row of bases. |  |
| `dec2` | `n -- s` | Hundredths as text with a decimal point. | `6213 dec2   gives "62.13"` |
| `alphabet` | `-- s` | The letters and digits passwords use. | `alphabet` |
| `password-of` | `n -- s` | A random password n characters long. | `12 password-of` |
| `bounce-step` | `ball -- ball` | Moves one ball a step and draws it. |  |
| `sort-col` | `mem i --` | Redraws one bar of sorting. |  |
| `star-step` | `star -- star` | Moves one star and draws it. |  |
| `startup` | `--` | Runs on tab 1 at boot: sys, then welcome. | `startup` |
| `show` | `o --` | Prints an ordinal in colour. | `omega show` |
| `fact` | `s q --` | Prints a label and what q gives. | `"1+w" [ 1 omega + ] fact` |
| `fortunes` | `-- l` | The facts fortune picks from. | `fortunes len` |
| `food-spot` | `-- n` | A random square for snake food. | `food-spot` |
| `draw-food` | `n --` | Draws snake food on a square. | `food-spot draw-food` |
| `vendor` | `id -- s` | The name of a PCI vendor. | `0x8086 vendor   gives "intel"` |
| `classes` | `-- l` | The PCI class names. | `classes len` |
| `class-name` | `n -- s` | The name of a PCI class. | `1 class-name   gives "storage"` |
| `mem-type` | `n -- s` | The name of a memory map type. | `1 mem-type   gives "usable"` |
| `reg>str` | `n -- s` | Four characters packed in a cpuid register. | `0 cpuid drop reg>str` |
| `edx-flags` | `-- l` | CPU feature names and bits for edx. | `edx-flags len` |
| `ecx-flags` | `-- l` | CPU feature names and bits for ecx. | `ecx-flags len` |
| `show-flags` | `reg flags --` | Prints which feature bits are set. | `1 cpuid nip nip nip edx-flags show-flags` |
| `memline` | `-- s` | Used and total memory as text. | `memline say` |
| `stat` | `label val --` | Prints one line of the sys screen. | `"os" "x" stat` |
| `logo-subverge` | `-- l` | The cat and moon logo, as a list of lines. | `logo-subverge len` |
| `logo-haelide` | `-- l` | The logo of the haelide theme. | `logo-haelide len` |
| `sys-line` | `line --` | Prints one line of a logo. | `"/\_/\" sys-line` |
| `sys-width` | `line -- n` | The width of one line of a logo. | `"abc" sys-width` |
| `user` | `-- s` | The user name on the sys screen. | `user say` |
| `os` | `-- s` | The OS name on the sys screen. | `os say` |
| `host` | `-- s` | The host name on the sys screen. | `host say` |
| `kernel-name` | `-- s` | The kernel name and version. | `kernel-name say` |
| `row` | `label val y --` | Prints one row of the top screen. | `"hi" "x" 3 row` |
| `leap?` | <code>y -- 1&#124;0</code> | 1 if y is a leap year. | `2024 leap?   gives 1` |
| `month-days` | `y m -- n` | How many days a month has. | `2024 2 month-days   gives 29` |
| `first-weekday` | `y m -- n` | Weekday of the 1st, 0 is Monday. | `2026 10 first-weekday` |
| `month-names` | `-- l` | The names of the months. | `month-names first` |
| `month-of` | `y m d --` | A month with day d marked. | `2026 10 19 month-of` |
| `set-at` | `l i x -- list` | A copy of l with item i replaced. | `[ 1 2 ] 0 9 set-at` |
| `slide-row` | `l -- l n` | Slides one row of tiles left. | `[ 2 2 4 0 ] slide-row` |
| `move-board` | `b lines -- b n` | Slides the whole tiles board. | `b left-lines move-board` |
| `left-lines` | `-- l` | Board rows in the order a left slide uses. | `left-lines` |
| `right-lines` | `-- l` | Board rows for a right slide. | `right-lines` |
| `up-lines` | `-- l` | Board columns for an up slide. | `up-lines` |
| `down-lines` | `-- l` | Board columns for a down slide. | `down-lines` |
| `spawn` | `b -- b` | Adds a 2 or a 4 on an empty square. | `b spawn` |
| `moves?` | <code>b lines -- 1&#124;0</code> | 1 if that slide changes the board. | `b up-lines moves?` |
| `can-move?` | <code>b -- 1&#124;0</code> | 1 if any slide changes the board. | `b can-move?` |
| `log2` | `n -- k` | How many times n halves to 1. | `1024 log2   gives 10` |
| `tile-color` | `n -- c` | The colour of a tile. | `8 tile-color` |
| `draw-tiles` | `b score --` | Draws the tiles board. | `b 0 draw-tiles` |
