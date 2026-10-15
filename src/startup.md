# Startup

At boot, tab 1 runs `startup`, defined as `[ sys welcome ] :startup` in the `sys` unit of [root](root.md). The other tabs start at a prompt.

## Changing it

    'startup open

and edit the definition. `[ sys ] :startup` drops the welcome text, and `[ ] :startup` starts at a bare prompt.

    'user open

changes the `user` in `user@subverge`. `host`, `os` and `kernel-name` set the other lines of the `sys` screen.

## Overriding it per tab

On an installed disk, tab 1's saved [world](world.md) is loaded before `startup` runs, and tab definitions take precedence over root ([names](names.md)). Defining `startup` in tab 1 therefore overrides the root version without changing it:

    [ "it's me again" say ] :startup

`'startup see` then shows your version in tab 1 and the root version in tab 2.

## Missing startup

If `startup` isn't defined, tab 1 runs `sys` instead. If root failed to build at boot, it shows `sys-c` and the root error in red.
