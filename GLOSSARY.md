# Glossary

## Dictionary

The list of candidate words searched to solve the puzzle. Not the
same as the word list containing only valid solutions. Supplied as
a newline-separated file via the `--dictionary` flag.

## Docbuild

An isolated nested package (located in the `docbuild` directory)
specifically configured to generate project API documentation using
`doc-gen4`. Keeping it separate avoids polluting the main package
with documentation tool dependencies.

## Letters

The pool of 4–9 unique ASCII lowercase characters (`a`–`z`) from
which candidate words are formed. Unicode lowercase codepoints
(e.g. `é`, `ñ`) are rejected at validation time.

## Mandatory Letter

The single character that must appear in every solved word. In
spelling bee puzzles, this is typically the centre letter. Must be
one of the puzzle's letters.

## Puzzle

The validated configuration containing the allowed letters, the mandatory
letter, the minimum word size, and the repeat permission.

In accordance with Lean 4's type safety guidelines, the
[`Puzzle`](Wordpuzzle/Basic.lean) type embeds both the
configuration values and formal mathematical proofs of their
validity as fields:

1. `h_size` — Proof that `4 ≤ size ∧ size ≤ 9`.
2. `h_letters_len` — Proof that the letters length is in `[4, 9]`.
3. `h_letters_lower` — Proof that letters are ASCII lowercase.
4. `h_letters_unique` — Proof that letters contain no duplicates.
5. `h_mandatory_lower` — Proof that the mandatory character is ASCII lowercase.
6. `h_mandatory_in` — Proof that the mandatory character is in the list.

The structure constructor is `private`, meaning a `Puzzle` can
only be instantiated via the [`validate`](Wordpuzzle/Basic.lean)
smart constructor. Once validated, all components of the
application can safely rely on these invariants without
re-verification.

## Repeats

A boolean flag controlling whether a letter from the pool may appear
more than once within a single candidate word. When enabled, the
solver mirrors the rules of the NYT Spelling Bee.

## Smart Constructor

A function (`validate`) that returns
`Except (List String) Puzzle`. It accumulates all validation
errors via six single-purpose validators, then performs a
single re-decision pass to extract the proof witnesses needed
by the `Puzzle` structure. This gives the user actionable
feedback for all failures in one attempt.

## Solver

The pure function (`solve`) that checks a single candidate word from the
dictionary against the puzzle configuration. It takes a `Puzzle` and a
`String` ("word") and returns an `Option String`, with no monadic
effects.

