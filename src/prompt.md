# Prompt

The `»` prompt reads a line and runs it. It is a simple line editor; for multi-line editing, use [scrawl](scrawl.md).

| Key | |
|---|---|
| Enter | runs the line |
| arrows, Home, End | move |
| Backspace, Delete | delete |
| Up, Down | earlier lines |
| Ctrl-C | throws the line away |
| F1 to F4 | switch [tab](tabs.md) |

The prompt has no tab completion.

A line can be up to 200 characters. Longer code belongs in a [definition](names.md) or a [root unit](units.md).

Up and Down recall the last 16 lines of the tab as text. To undo the effect of a line, use [back](back.md).

The keyboard has no key for omega or aleph. Use `\w` and `\A` in strings, or the words `omega` and `aleph0`.
