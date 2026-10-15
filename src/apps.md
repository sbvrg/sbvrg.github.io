# Apps

`apps` lists the programs that come with Subverge, described in [tools](tools.md), [games](games.md), [demos](demos.md) and [learn](learn.md). `q` exits almost all of them.

![apps](images/43-apps.png)

## Adding a program

A program is just a word, so `apps` can't tell programs from helpers. It prints the hand-written `app-list` from the `apps` unit instead. To add `hello`:

    'apps open

and put this line inside the outer `[ [ ... ] ]`:

    [ "hello" "Says hello." ]

The entry appears as soon as the unit builds.

![Editing the list](images/50-apps-editor.png)

![apps with hello](images/51-apps-hello.png)

## Tab definitions

The list lives in root, so every tab lists `hello`, but only the tab that defined it can run it. Put the program itself in a [unit](units.md) as well.

Keep descriptions short, or they overflow into the next column.
