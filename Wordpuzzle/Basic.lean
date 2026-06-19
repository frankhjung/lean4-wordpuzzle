import Batteries.Tactic.Lint

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
  /-- Whether letters can be repeated in the candidate word. -/
  repeats : Bool
  /-- The minimum size/length of the words to be found. -/
  size : Nat
  /-- The pool of unique ASCII lowercase letters. -/
  letters : String
  /-- The mandatory character that every solution must contain. -/
  mandatory : Char
  deriving Inhabited

deriving instance Repr for Puzzle

attribute [nolint unusedArguments] instReprPuzzle.repr

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
    (mandatory : Char) : Except (List String) Puzzle :=
  let errs := validateSize size ++
              validateLetters letters ++
              validateMandatory mandatory letters
  if errs.isEmpty then
    Except.ok { repeats, size, letters, mandatory }
  else
    Except.error errs

/-- Finds all valid words for a given puzzle from a word list.

A candidate word from `dictionaryWords` is accepted when all of the
following hold:
- Its is at least `puzzle.size` characters long.
- Every character appears in `puzzle.letters`.
- It contains `puzzle.mandatory`.
- When `puzzle.repeats` is `false`, no character appears more than
  once.

Returns the accepted words (trimmed). -/
def solve (puzzle : Puzzle) (word : String) : Option String :=
  let mandatory := puzzle.mandatory
  let puzzleChars := puzzle.letters.toList
  let cleanWord := word.trimAscii.toString
  let chars := cleanWord.toList
  if chars.length >= puzzle.size && -- valid word size (4-9 inclusive)
     cleanWord.contains mandatory && -- word has mandatory letter
     chars.all (fun c => puzzleChars.contains c) && -- word has valid letters
     (puzzle.repeats || !hasDuplicates chars) -- toggle duplicates letters
  then
    some cleanWord  -- valid word
  else
    none            -- invalid word, skip

end Wordpuzzle
