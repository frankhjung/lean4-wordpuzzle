import Batteries.Tactic.Lint

namespace Wordpuzzle

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


/-- Represents a word-puzzle configuration.

Fields:
- `repeats`    – when `true`, a letter may appear more than once in a
                 candidate word.
- `size`       – minimum word length (4–9 inclusive).
- `letters`    – the pool of unique ASCII lowercase letters available
                 to form words.
- `mandatory`  – a letter from `letters` that every valid word must
                 contain. -/
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
  /-- Proof that size is between 4 and 9 inclusive. -/
  h_size : 4 ≤ size ∧ size ≤ 9
  /-- Proof that letters length is between 4 and 9 inclusive. -/
  h_letters_len : 4 ≤ letters.length ∧ letters.length ≤ 9
  /-- Proof that letters are all ASCII lowercase. -/
  h_letters_lower : letters.toList.all isAsciiLower = true
  /-- Proof that letters contain no duplicates. -/
  h_letters_unique : hasDuplicates letters.toList = false
  /-- Proof that the mandatory character is ASCII lowercase. -/
  h_mandatory_lower : isAsciiLower mandatory = true
  /-- Proof that the mandatory character is in letters. -/
  h_mandatory_in : letters.toList.contains mandatory = true

instance : Inhabited Puzzle where
  default := {
    -- need valid (placeholder) examples for compile proof
    repeats := false
    size := 4
    letters := "cadevrsoi"
    mandatory := 'c'
    h_size := by decide
    h_letters_len := by decide
    h_letters_lower := by rfl
    h_letters_unique := by rfl
    h_mandatory_lower := by rfl
    h_mandatory_in := by rfl
  }

deriving instance Repr for Puzzle

attribute [nolint unusedArguments] instReprPuzzle.repr

/-- Validates that the minimum word size is between 4 and 9
inclusive. -/
def validateSize (size : Nat) : List String :=
  if (4 ≤ size ∧ size ≤ 9 : Prop) then []
  else [s!"Size must be between 4 and 9 (got {size})"]

/-- Validates that the letters list contains between 4 and 9
characters. -/
def validateLettersLen (letters : String) : List String :=
  if (4 ≤ letters.length ∧ letters.length ≤ 9 : Prop) then []
  else
    [s!"Letters length must be between 4 and 9 (got {letters.length})"]

/-- Validates that all letters are ASCII lowercase characters. -/
def validateLettersLower (letters : String) : List String :=
  if letters.toList.all isAsciiLower then []
  else
    ["Letters must all be ASCII lowercase letters (a-z)"]

/-- Validates that the letters pool contains no duplicate
characters. -/
def validateLettersUnique (letters : String) : List String :=
  if hasDuplicates letters.toList then ["Letters must be unique"]
  else []

/-- Validates that the mandatory letter is an ASCII lowercase
character. -/
def validateMandatoryLower (mandatory : Char) : List String :=
  if isAsciiLower mandatory then []
  else
    ["Mandatory letter must be an ASCII lowercase letter (a-z)"]

/-- Validates that the mandatory letter is present in the letters
pool. -/
def validateMandatoryIn (mandatory : Char) (letters : String)
    : List String :=
  if letters.toList.contains mandatory then []
  else
    ["Mandatory letter must be one of the puzzle letters"]

/-- Constructs a validated `Puzzle`, or returns accumulated errors.

Runs all field validators and collects every error message.
Returns `Except.ok puzzle` when there are no errors, or
`Except.error errs` with the full list of messages otherwise.

When all validators pass the error list is empty, so the
corresponding decidable checks are guaranteed to succeed and
the proof witnesses are extracted in a single re-decision
pass. -/
def validate (repeats : Bool) (size : Nat) (letters : String)
    (mandatory : Char) : Except (List String) Puzzle :=
  let errs :=
    validateSize size ++
    validateLettersLen letters ++
    validateLettersLower letters ++
    validateLettersUnique letters ++
    validateMandatoryLower mandatory ++
    validateMandatoryIn mandatory letters
  if errs.isEmpty then
    if h₁ : 4 ≤ size ∧ size ≤ 9 then
    if h₂ : 4 ≤ letters.length ∧ letters.length ≤ 9 then
    if h₃ : letters.toList.all isAsciiLower = true then
    if h₄ : hasDuplicates letters.toList = false then
    if h₅ : isAsciiLower mandatory = true then
    if h₆ : letters.toList.contains mandatory = true then
      .ok { repeats, size, letters, mandatory,
            h_size := h₁, h_letters_len := h₂,
            h_letters_lower := h₃, h_letters_unique := h₄,
            h_mandatory_lower := h₅, h_mandatory_in := h₆ }
    else .error errs
    else .error errs
    else .error errs
    else .error errs
    else .error errs
    else .error errs
  else
    .error errs

/-- Solves a word puzzle for a single candidate word.

A candidate word is accepted when all of the following hold:
- Its length is at least `puzzle.size` characters.
- Every character appears in `puzzle.letters`.
- It contains `puzzle.mandatory`.
- When `puzzle.repeats` is `false`, no character appears more than
  once.

Returns the accepted word (trimmed) as `some String`, or `none` if the
word is rejected. -/
def solve (puzzle : Puzzle) (word : String) : Option String := do
  let puzzleChars := puzzle.letters.toList -- puzzle as chars
  let cleanWord := word.trimAscii.toString -- trim word
  let wordChars := cleanWord.toList        -- words as chars
  guard (
    wordChars.length >= puzzle.size && -- valid word size (4-9 inclusive)
    cleanWord.contains puzzle.mandatory && -- word has mandatory letter
    wordChars.all (fun c => puzzleChars.contains c) && -- word has valid letters
    (puzzle.repeats || !hasDuplicates wordChars) -- check against repeats flag
  )
  return cleanWord

end Wordpuzzle
