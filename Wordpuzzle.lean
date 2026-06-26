import Cli
import Wordpuzzle.Basic
import Wordpuzzle.Config

open Cli
open Wordpuzzle (validate solve appVersion Puzzle)

/-- `ParseableType` instance so that `Cli` can parse a `System.FilePath`
flag from a raw string argument. -/
instance : ParseableType System.FilePath where
  name := "FilePath"
  parse? s := some ⟨s⟩

/-- `ParseableType` instance so that `Cli` can parse a single `Char`
flag from a raw string argument.

Returns `none` when the string is not exactly one character long. -/
instance : ParseableType Char where
  name := "Char"
  parse? s := if s.length == 1 then some s.front else none

/-- Streams the dictionary handle, solving and printing matching words.

Note here that we must use recursive streaming:

1. Stateful Operating System Handles:
    - The dictionary is read via an `IO.FS.Handle`, which is an effectful,
      stateful resource, not a pure container (like a `List` or `Array`).
    - `fmap` is a stateless mapping function over a functor (such as mapping a
      function over the result of a single read `IO` action). It cannot loop
      repeatedly or read subsequent lines from a file pointer.
2. Sequential State Tracking (`foundAny`):
    - The loop carries state (the `foundAny` boolean flag) from one line to
      the next to determine whether to print "No words found." at the end.
    - A standard `fmap` does not propagate state between elements. Carrying
      state would require a monadic fold (like `foldlM`) or a state monad.
3. Absence of Native Monadic Streams:
    - Lean 4 does not provide a standard lazy stream adapter for file handles
      that allows mapping directly. Therefore, recursive streaming is the
      idiomatic approach to process file contents line-by-line in constant
      memory.
4. Streaming versus In-Memory Fold:
    - The dictionary contains about 63,000 words. So the execution time
      difference would be negligible (both execute in milliseconds), making the
      memory-efficient streaming approach the cleaner and more scalable design
      choice.
-/
partial def streamPuzzle (handle : IO.FS.Handle) (puzzle : Puzzle)
    (foundAny : Bool) : IO UInt32 := do
  let line ← handle.getLine
  if line.isEmpty then
    if !foundAny then
      IO.println "No words found."
    pure (0 : UInt32)
  else
    match solve puzzle line with
    | some matchWord =>
      IO.println matchWord
      streamPuzzle handle puzzle true
    | none =>
      streamPuzzle handle puzzle foundAny

/-- CLI command handler for the word-puzzle solver.

Extracts flag values from the parsed `Cli` arguments, validates them via
`Wordpuzzle.validate`, and streams the dictionary to filter words via
`Wordpuzzle.solve`.

Returns exit code `0` on success, or `1` when validation fails, the dictionary
is missing, or an I/O error occurs. -/
def runWordpuzzleCmd (p : Parsed) : IO UInt32 := do
  let repeats := p.hasFlag "repeats"
  let size := (p.flag! "size").as! Nat
  let letters := (p.flag! "letters").as! String
  let mandatory := (p.flag! "mandatory").as! Char
  let dictionary := (p.flag! "dictionary").as! System.FilePath
  let validation := validate repeats size letters mandatory
  match validation with
  | Except.error errs =>
    errs.forM IO.println
    return (1 : UInt32)
  | Except.ok puzzle =>
    if !(← System.FilePath.pathExists dictionary) then
      IO.println "Dictionary file does not exist"
      return (1 : UInt32)
    try
      let handle ← IO.FS.Handle.mk dictionary IO.FS.Mode.read
      streamPuzzle handle puzzle false
    catch e =>
      IO.println s!"Failed to read dictionary file: {e}"
      return (1 : UInt32)

/-- The top-level `Cli` command descriptor for the word-puzzle solver.

Defines the command name, version (`0.1.0`), description, all
supported flags, and default values for `size` and `dictionary`. -/
def wordpuzzleCmd : Cmd := `[Cli|
  wordpuzzleCmd VIA runWordpuzzleCmd; [appVersion]
  "Solve word puzzles"

  FLAGS:
    r, repeats; "Allow letters to repeat (like NYT Spelling Bee)"
    s, size : Nat; "Minimum word size is (4-9)"
    l, letters : String; "Unique lowercase letters to make words (4-9)"
    m, mandatory : Char; "Mandatory lowercase letter that must be in the words"
    d, dictionary : System.FilePath; "Dictionary to search for words"

  EXTENSIONS:
    require! #["letters", "mandatory"];
    defaultValues! #[("size", "4"), ("dictionary", "dictionary")]
  ]

/-- Entry point. Delegates argument parsing to `wordpuzzleCmd`. -/
def main (args : List String) : IO UInt32 :=
  wordpuzzleCmd.validate args
