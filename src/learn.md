# learn

`learn` is the built-in tutorial.

## Using it

    learn               starts at the beginning
    14 lesson           starts at lesson 15

Each lesson suggests a line, and you can type it or your own. A failing line restores the stack. Space goes on, `b` goes back and `q` quits. Quitting restores your stack, but definitions made during the lessons are kept.

![learn, big numbers](images/35-learn-big.png)

## Contents

The lessons start with the stack, numbers, strings and quotes, then cover definitions, locals and dynamic scope, control flow, transactions, `back` and `try`. Later ones cover tabs, time and keys, drawing, ordinals and cardinals, machine access and the JIT, and end with writing a program, adding it to `apps`, root units and saving.

![learn, the last lesson](images/36-learn-last.png)

## Changing it

The lessons are a list called `lessons` in `root/80-learn.om`. `'learn open` opens it, and changes take effect as soon as the unit rebuilds.
