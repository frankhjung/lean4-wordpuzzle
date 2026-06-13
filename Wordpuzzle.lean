import Cli
import Wordpuzzle.Basic
import Wordpuzzle.Config

open Cli
open Wordpuzzle (validate Env runPuzzle appVersion)

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

/-- The production `Env` implementation that performs real I/O.

- `pathExists` delegates to `System.FilePath.pathExists`.
- `readLines`  reads every line of the file via `IO.FS.lines`, wrapping
               any exception as an error string.
- `println`    delegates to `IO.println`. -/
def realEnv : Env IO where
  pathExists path := System.FilePath.pathExists path
  readLines path := do
    try
      let lines ← IO.FS.lines path
      pure (Except.ok lines.toList)
    catch e =>
      pure (Except.error (toString e))
  println str := IO.println str

/-- CLI command handler for the word-puzzle solver.

Extracts flag values from the parsed `Cli` arguments, validates them
via `Wordpuzzle.validate`, and delegates solving to `runPuzzle`.

Returns exit code `0` on success, or `1` when validation fails or an
I/O error occurs. Prints help and returns `0` when the mandatory
`--letters` or `--mandatory` flags are absent. -/
def runWordpuzzleCmd (p : Parsed) : IO UInt32 := do
  if !p.hasFlag "letters" || !p.hasFlag "mandatory" then
    p.printHelp
    return 0

  let repeats := p.hasFlag "repeats"
  let size := (p.flag! "size").as! Nat
  let letters := (p.flag! "letters").as! String
  let mandatory := (p.flag! "mandatory").as! Char
  let dictionary := (p.flag! "dictionary").as! System.FilePath
  let validation := validate repeats size letters mandatory dictionary
  match validation with
  | Except.error errs =>
    errs.forM IO.println
    return 1
  | Except.ok puzzle =>
    runPuzzle realEnv puzzle

/-- The top-level `Cli` command descriptor for the word-puzzle solver.

Defines the command name, version (`0.1.0-dev`), description, all
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
    defaultValues! #[("size", "4"), ("dictionary", "dictionary")]
  ]

/-- Entry point. Delegates argument parsing to `wordpuzzleCmd`. -/
def main (args : List String) : IO UInt32 :=
  wordpuzzleCmd.validate args
