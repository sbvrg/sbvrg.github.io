# Features

<div class="feats">
<div class="feat"><svg viewBox="0 0 48 48"><rect x="5" y="8" width="38" height="32" rx="1"/><path d="M12 18l6 5-6 5M22 30h12"/></svg><div><h3>A stack language for a shell</h3><p>The prompt runs <a href="omega.html">omega</a>, a postfix language related to Forth. Commands and programs are written in the same language.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M14 18H32a10 10 0 0 1 0 20H20"/><path d="M20 10l-8 8 8 8"/></svg><div><h3>Every line is a transaction</h3><p>When a word on a line fails, the whole line is undone. <a href="back.html">back</a> undoes up to 64 lines that succeeded, and <code>redo</code> reverses a <code>back</code>.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M17 6l-4 36M33 6l-4 36M8 17h34M6 31h34"/></svg><div><h3>Exact integers</h3><p>Integers that overflow 64 bits become <a href="bignums.html">bignums</a>, up to 2^65536. Compiled code does the same.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M24 24c-5-7-9-10-13-10a10 10 0 0 0 0 20c4 0 8-3 13-10s9-10 13-10a10 10 0 0 1 0 20c-4 0-8-3-13-10z"/></svg><div><h3>Infinity as a value</h3><p><code>omega</code> and <code>aleph0</code> can be added, multiplied and compared like other numbers. See <a href="ordinals.html">ordinals</a> and <a href="cardinals.html">cardinals</a>.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><rect x="12" y="12" width="24" height="24" rx="2"/><path d="M18 6v6M24 6v6M30 6v6M18 36v6M24 36v6M30 36v6M6 18h6M6 24h6M6 30h6M36 18h6M36 24h6M36 30h6"/></svg><div><h3>A JIT with a disassembler</h3><p>A quote is compiled to x86-64 machine code the second time it runs. <code>xray</code> disassembles the result. See <a href="jit.html">JIT</a>.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M5 16h10l2-5h9l2 5h15v24H5z"/><path d="M5 16v-5h10"/></svg><div><h3>Four tabs</h3><p>Four <a href="tabs.html">tabs</a> run at the same time under a preemptive scheduler. Each tab has its own stack and its own definitions.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><circle cx="17" cy="24" r="9"/><path d="M26 24h17M37 24v7M43 24v5"/></svg><div><h3>Ring 0</h3><p>All code runs in ring 0. <code>peek</code>, <code>poke</code>, <code>in</code>, <code>out</code>, <code>cpuid</code> and <code>pci</code> read and write memory, I/O ports and PCI devices. See <a href="smarties.html">omega for smarties</a>.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M8 8h26l6 6v26H8z"/><path d="M15 8v10h16V8M14 40V27h20v13"/></svg><div><h3>Saved after every line</h3><p>An installed system writes its state to disk after every line that succeeds. The state is stored as omega source. See <a href="saving.html">saving</a>.</p></div></div>
<div class="feat"><svg viewBox="0 0 48 48"><path d="M24 6v16"/><path d="M14 12a15 15 0 1 0 20 0"/></svg><div><h3>Its own bootloader</h3><p>Installed disks boot with Subverge's own MBR and second stage loader. GRUB is used only on the ISO. See <a href="boot.html">boot</a>.</p></div></div>
</div>

## Requirements

- QEMU. Subverge has only been tested in QEMU.
- 256 MB of RAM for the virtual machine.
- A disk image you don't care about, if you want to [install](installation.md) it.
- Some programming experience.

## What it looks like

    2 100 ^ .              1267650600228229401496703205376
    [ dup * ] :sq          defines sq
    7 sq .                 49
    omega 1 + .            ω+1
    1 omega + omega = .    1
    [ 3 1 2 ] sort .       [ 1 2 3 ]
    'haelide theme         switches to haelide

![haelide](images/80-theme-haelide.png)
