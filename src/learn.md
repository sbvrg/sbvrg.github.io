# learn

`learn` is the tutorial built into Subverge. It teaches omega from the stack upwards, one screen per lesson, and each lesson gives you a line to run so you see the result straight away. It assumes you can already program in some language, and it moves quickly.

## Starting

    learn               starts at the first lesson
    14 lesson           starts at lesson 15

Lessons are numbered from 1 on screen, and `lesson` counts from 0 like the rest of omega, so `14 lesson` opens the lesson the header calls `learn 15`.

![learn, big numbers](images/35-learn-big.png)

## How a lesson works

Each lesson shows a title, a short explanation and a suggested line under `Run this, or type your own line:`. The prompt that follows works like the normal [prompt](prompt.md), without history.

- Press Enter on an empty line to skip the exercise.
- Type the suggested line, or anything else, and press Enter to run it.

The lesson then shows the stack after your line. Each lesson starts from an empty stack. If your line fails, the error is printed and the stack is put back as it was before the line, so a mistake never leaves the lesson in a strange state.

After the exercise, any key moves to the next lesson, `b` goes back one, and `q`, Escape or Ctrl-C leaves.

> **Note:** Ctrl-C at the exercise prompt itself cancels the whole tutorial with the error `cancelled`. Since the tutorial is one line, that also undoes every definition made during it. Leave with `q` after an exercise instead.

## What it keeps

When you leave, `learn` clears the screen and puts back the stack you had before starting. Definitions you made during the lessons are kept, so a word written in the lesson on definitions can be used afterwards.

The whole tutorial runs as a single line, so all the definitions you made in it arrive together as one change to your [world](world.md), and one `back` removes all of them.

## Lessons

| | Lesson | | Lesson |
|---|---|---|---|
| 1 | Operand stack | 21 | Tabs |
| 2 | Postfix evaluation | 22 | Help |
| 3 | Stack words | 23 | Time |
| 4 | Integers | 24 | Keys |
| 5 | Big numbers | 25 | Drawing |
| 6 | Truth | 26 | Themes |
| 7 | Strings | 27 | Ordinals |
| 8 | Quotes | 28 | Cardinals |
| 9 | Definitions | 29 | Counting past infinity |
| 10 | Reflection | 30 | Machine access |
| 11 | Locals | 31 | JIT |
| 12 | Dynamic scope | 32 | Programs |
| 13 | Conditionals | 33 | Small tools |
| 14 | Loops | 34 | Editing a word |
| 15 | Recursion | 35 | Writing a program |
| 16 | Tracing | 36 | Registering it in apps |
| 17 | Lists | 37 | Checking the entry |
| 18 | Transactions | 38 | Root units |
| 19 | Undo | 39 | Persistence |
| 20 | Catching errors | 40 | Where next |

The first half is the language: the stack, values, definitions, locals and their dynamic scope, control flow and lists. The middle covers what makes Subverge different, namely [transactions](transactions.md), [back](back.md), `try`, [tabs](tabs.md), [themes](themes.md), and the ordinals and cardinals. The last part walks through writing a small program, adding it to [apps](apps.md) and putting it in a [root unit](units.md) so it is saved.

![learn, the last lesson](images/36-learn-last.png)

## Changing the lessons

The tutorial is ordinary omega in the `learn` unit of [root](root.md):

    'learn open

The lessons are a list called `lessons`. Each entry is a list of three strings: the title, the text, and the suggested line, which can be empty for a lesson without an exercise. Lines of text start with two spaces and are separated with `\n`. Adding an entry adds a lesson, and the change takes effect as soon as the unit builds.

The runner, `lesson`, shows how the exercises are made safe. It saves the stack with `depth list`, runs your line with `eval` inside `try`, and spreads the saved stack back if `try` leaves `0`. The same technique works in any program that runs code typed by the user ([catching](catching.md)).
