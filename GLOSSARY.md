# Glossary

## Dictionary

The list of candidate words searched to solve the puzzle.  Not the
same as the word list containing only valid solutions.  Supplied as
a newline-separated file via the `--dictionary` flag.

## Letters

The pool of 4–9 unique ASCII lowercase characters (`a`–`z`) from
which candidate words are formed.  Unicode lowercase codepoints
(e.g. `é`, `ñ`) are rejected at validation time.

## Mandatory Letter

The single character that must appear in every solved word.  In
spelling bee puzzles, this is typically the centre letter.  Must be
one of the puzzle's letters.

## Puzzle

The validated configuration containing the allowed letters, the
mandatory letter, the minimum word size, and the repeat permission.
Constructed exclusively through `validate` (a smart constructor); the
raw `mk` constructor is `private`.

## Repeats

A boolean flag controlling whether a letter from the pool may appear
more than once within a single candidate word.  When enabled, the
solver mirrors the rules of the NYT Spelling Bee.

## Smart Constructor

A function (`validate`) that returns `Except (List String) Puzzle`.
It accumulates all validation errors in a single pass rather than
short-circuiting on the first failure, giving the user actionable
feedback in one attempt.

## Solver

The pure function (`solve`) that checks a single candidate word from the
dictionary against the puzzle configuration. It takes a `Puzzle` and a
`String` ("word") and returns an `Option String`, with no monadic
effects.
