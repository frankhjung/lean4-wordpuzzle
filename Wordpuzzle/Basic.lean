namespace Wordpuzzle

/-- Represents a word-puzzle configuration.

Fields:
- `repeats`    – when `true`, a letter may appear more than once in a
                 candidate word.
- `size`       – minimum word length (4–9 inclusive).
- `letters`    – the pool of unique ASCII lowercase letters available
                 to form words.
- `mandatory`  – a letter from `letters` that every valid word must
                 contain.
- `dictionary` – path to the newline-separated word list used for
                 solving. -/
structure Puzzle where
  private mk ::
  repeats : Bool
  size : Nat
  letters : String
  mandatory : Char
  dictionary : System.FilePath
  deriving Repr, Inhabited

/-- Returns `true` when the character is an ASCII lowercase letter
(`a`–`z`).

Unicode lowercase codepoints such as `'é'` or `'ñ'` are excluded
to match the ASCII-only constraint of word puzzles. -/
private def isAsciiLower (c : Char) : Bool :=
  decide ('a' ≤ c ∧ c ≤ 'z')

/-- Returns `true` when the list contains at least one duplicated
element.

Uses a linear scan; each element is checked for membership in the
remainder of the list, giving O(n²) time.  This is adequate for
the short lists encountered in word-puzzle solving (≤ 9 letters,
short dictionary words). -/
def hasDuplicates {α : Type} [BEq α] : List α → Bool
  | [] => false
  | x :: xs => xs.contains x || hasDuplicates xs

/-- Validates the `size` field of a puzzle.

Returns an empty list on success, or a singleton list containing a
human-readable error message when `size` falls outside [4, 9]. -/
def validateSize (size : Nat) : List String :=
  if size < 4 || size > 9 then
    [s!"Size must be between 4 and 9 (got {size})"]
  else
    []

/-- Validates the `letters` field of a puzzle.

Checks that:
1. The length of `letters` is in [4, 9].
2. Every character is an ASCII lowercase letter (`a`-`z`).
3. No character appears more than once.

Returns a (possibly empty) list of error messages, one per failed
condition. -/
def validateLetters (letters : String) : List String :=
  let len := letters.length
  let chars := letters.toList
  let conds := [
    (len < 4 || len > 9,
     s!"Letters length must be between 4 and 9 (got {len})"),
    (!chars.all isAsciiLower,
     "Letters must all be ASCII lowercase letters (a-z)"),
    (hasDuplicates chars,
     "Letters must be unique")
  ]
  conds.filterMap (fun (cond, msg) => if cond then some msg else none)

/-- Validates the `mandatory` field of a puzzle.

Checks that:
1. `mandatory` is an ASCII lowercase letter (`a`–`z`).
2. `mandatory` appears in `letters`.

Returns a (possibly empty) list of error messages, one per failed
condition. -/
def validateMandatory (mandatory : Char) (letters : String) :
    List String :=
  let conds := [
    (!isAsciiLower mandatory,
     "Mandatory letter must be an ASCII lowercase letter (a-z)"),
    (!letters.contains mandatory,
     "Mandatory letter must be one of the puzzle letters")
  ]
  conds.filterMap (fun (cond, msg) => if cond then some msg else none)

/-- Constructs a validated `Puzzle`, or returns accumulated errors.

Runs all field validators in sequence and collects every error
message.  Returns `Except.ok puzzle` when there are no errors, or
`Except.error errs` with the full list of messages otherwise. -/
def validate (repeats : Bool) (size : Nat) (letters : String)
    (mandatory : Char) (dictionary : System.FilePath) :
    Except (List String) Puzzle :=
  let errs := validateSize size ++
              validateLetters letters ++
              validateMandatory mandatory letters
  if errs.isEmpty then
    Except.ok { repeats, size, letters, mandatory, dictionary }
  else
    Except.error errs

/-- Finds all valid words for a given puzzle from a word list.

A candidate word from `dictionaryWords` is accepted when all of the
following hold:
- Its lowercase form is at least `puzzle.size` characters long.
- Every character in its lowercase form appears in `puzzle.letters`.
- It contains `puzzle.mandatory`.
- When `puzzle.repeats` is `false`, no character appears more than
  once.

Returns the accepted words in their original (trimmed) casing. -/
def solve (puzzle : Puzzle) (dictionaryWords : List String) :
    List String :=
  let mandatory := puzzle.mandatory
  let puzzleChars := puzzle.letters.toList
  let check (word : String) : Option String :=
    let cleanWord := word.trimAscii.toString
    let lowerWord := cleanWord.toLower
    let chars := lowerWord.toList
    if chars.length >= puzzle.size &&
       chars.all (fun c => puzzleChars.contains c) &&
       lowerWord.contains mandatory &&
       (puzzle.repeats || !hasDuplicates chars) then
      some cleanWord
    else
      none
  dictionaryWords.filterMap check

/-- Abstraction over side-effectful environment operations.

Parameterised by a monad `m` so that the core logic in `runPuzzle`
can be tested without real I/O by substituting a pure or mock
monad.

Fields:
- `pathExists` – checks whether a file-system path exists.
- `readLines`  – reads all lines from a file, returning an error
                 string on failure.
- `println`    – writes a line to standard output. -/
structure Env (m : Type → Type) where
  pathExists : System.FilePath → m Bool
  readLines  : System.FilePath → m (Except String (List String))
  println    : String → m Unit

/-- Formats a list of solutions for display.

Returns `"No words found."` when `solutions` is empty; otherwise
joins the words with newline characters. -/
def formatSolutions (solutions : List String) : String :=
  if solutions.isEmpty then
    "No words found."
  else
    String.intercalate "\n" solutions

/-- Runs a puzzle against its dictionary file using the supplied
`Env`.

1. Checks that the dictionary path exists; prints an error and
   returns exit code `1` if not.
2. Reads the dictionary lines; prints an error and returns `1` on
   failure.
3. Solves the puzzle and prints the formatted solutions.

Returns `0` on success, `1` on any I/O or file error. -/
def runPuzzle [Monad m] (env : Env m) (puzzle : Puzzle) :
    m UInt32 := do
  if !(← env.pathExists puzzle.dictionary) then
    env.println "Dictionary file does not exist"
    return 1
  match ← env.readLines puzzle.dictionary with
  | Except.error err =>
    env.println s!"Failed to read dictionary file: {err}"
    return 1
  | Except.ok lines =>
    let solutions := solve puzzle lines
    env.println (formatSolutions solutions)
    return 0

end Wordpuzzle
