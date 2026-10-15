# Games

Games and visual demos, drawn directly on the text [screen](screen.md). Their source is a good reference for full-screen programs, for example `'snake open`.

## Games

**`snake`** is steered with the arrow keys and **`pong`** with left and right. **`life`** runs Conway's Game of Life on raw memory from `alloc`. `q` quits all three.

![snake](images/25-snake.png)

![pong](images/62-pong.png)

![life](images/26-life.png)

## Visual demos

**`rain`**, **`stars`**, **`bounce`**, **`sieve`** (the sieve of Eratosthenes), **`sorting`** (bubble sort as bars) and **`fortune`**.

![rain](images/27-rain.png)

![sieve](images/45-sieve-done.png)

![sorting](images/47-sorting-running.png)

Running several in other [tabs](tabs.md) and then `top` shows them all at once.

## Writing your own

They all follow the same pattern: `wipe` and `nocursor`, then a `while` loop that checks `key?`, draws with `put` and `text` and `sleep`s a tick, and finally `wipe` and `"omega" title`. `quit-key?` checks for `q`, Esc and Ctrl-C. Put your program in a [unit](units.md) and add it to [apps](apps.md).
