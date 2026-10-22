# What's new

## Subverge 0.9.3

Subverge 0.9.3 comes with ordinal 1.0.3 and omega 1.0.3. Get it from the [releases page](https://github.com/texivi/Subverge/releases/tag/v0.9.3).

### Text and windows in graphics mode

`text` now draws in graphics mode, using the same arguments as in the text screen. The new `window` word draws a frame with a title bar:

    gfx 40 40 300 160 "first" window "hello" 60 90 14 text key drop gfx-off

![window](images/93-window.png)

`window` takes `x y w h title --`. See [screen](screen.md).

## Subverge 0.9.2

Subverge 0.9.2 comes with ordinal 1.0.2 and omega 1.0.2. Get it from the [releases page](https://github.com/texivi/Subverge/releases/tag/v0.9.2).

### beep

`beep` plays a tone on the PC speaker. It takes a pitch in hertz and a length in ticks:

    440 50 beep

`440 50 beep` plays an A for half a second. The pitch has to be between 20 and 20000. Ctrl-C stops the tone. QEMU plays it when started with an audio backend that supports the speaker, for example `-audiodev pa,id=a -machine pcspk-audiodev=a`. See [ports](ports.md).

### Graphics mode

`gfx` switches to 640 by 480 graphics with the sixteen colours of the current theme. `dot` sets a pixel and `box` fills a rectangle, and `gfx-off` goes back to the text screen:

    gfx 20 20 100 60 5 box key drop gfx-off

![graphics](images/92-gfx.png)

The picture is made of eight `box` calls, listed in [screen](screen.md).

F1 to F4 also leave graphics mode. It needs QEMU's default `-vga std` display. This is the first step toward the planned desktop with windows. See [screen](screen.md).

## Subverge 0.9.1

Subverge 0.9.1 comes with ordinal 1.0.1 and omega 1.0.1. Get it from the [releases page](https://github.com/texivi/Subverge/releases/tag/v0.9.1).

### The haelide theme

    'haelide theme

![haelide](images/80-theme-haelide.png)

`haelide` also switches `sys` to the `haelide` logo. See [themes](themes.md).

### Logos

`sys` can draw other logos. `logos` lists them, `'haelide logo` switches, and `logo@` gives the current name. A logo is a word named `logo-` and the logo's name, so you can draw your own:

    [ [ "  .-." " (o o)" [ " | O |" "  mine" ] "  '~'" ] ] :logo-mine
    'mine logo

![a custom logo](images/87-logo-mine.png)

An installed system remembers the logo across reboots. See [logos](logos.md).

### type

`type` names the kind of a value:

    [ 1 ] type say      list
    5 type say          number
    "x" type say        string
    'x type say         symbol

### fail

`fail` fails the line with your own message, the same way a built-in word fails:

    [ { n } n 0 < [ "negative" fail ] when n sqrt ] :root-of
    -4 root-of
      ! negative

Inside `try` it is caught like any other error ([catching](catching.md)).

### Fixes

- Ordinal arithmetic whose coefficient would pass 64 bits, such as `omega 4294967296 * 4294967296 *`, gave a wrong result. It now fails with `that coefficient doesn't fit in 64 bits`.

### Upgrading from 0.9.0

The disk layout is the same as in 0.9.0, with the logo name added to the state header. A root saved by 0.9.0 still has the old `sys`, which doesn't know about logos. See [upgrading an installed disk](installation.md#upgrading-an-installed-disk).
