# scrawl

scrawl is the Subverge text editor. It is opened by one of:

    'top open           the root unit that defines top
    'sq edit            a definition in this tab
    "mine" unit         a new root unit

## Keys

| Key | |
|---|---|
| arrows, Home, End, Page Up, Page Down | move |
| Ctrl-T, Ctrl-B | top, bottom |
| Ctrl-F | find, and Enter on an empty search repeats it |
| Ctrl-K | cut the line |
| Ctrl-U | paste it above the cursor |
| Ctrl-S | save |
| Ctrl-Q | quit, twice if there are unsaved changes |
| Tab | spaces to the next multiple of 4 |

scrawl has no undo and no selection, and the clipboard holds a single line.

## Saving and quitting

Ctrl-S saves the text, and the rebuild happens on quit, using the last saved version. Quitting without saving changes nothing. A root unit rebuilds all or nothing ([root](root.md)), and the result is [saved](saving.md) to disk.

## edit

`'name edit` opens the body of a definition without its outer brackets, and redefines `name` in your tab on quit. As a result:

- `'newname edit` on an undefined name creates a new word, which is convenient for longer definitions.
- `'top edit` on a root word creates a private copy in your tab. Use `open` to change root itself.
- If the text doesn't parse, it is kept as a string and scrawl reports `that didn't parse` with the reason. The word then pushes that string until it is edited and fixed.
