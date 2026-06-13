import Wordpuzzle.Basic
import Wordpuzzle.Version
import Test.Util
open Wordpuzzle (appVersion)

namespace Test.Basic

open Test.Util (assertEqual State MockFs mkMockEnv)
open Wordpuzzle (
  validate Puzzle validateSize validateLetters validateMandatory
  solve Env runPuzzle formatSolutions
)

/-!
## Test helpers
-/

/-- Builds a `Puzzle` via `validate` for use in tests that need a
valid puzzle as *input* (e.g. `solve`, `runPuzzle`).

Panics at test runtime if the arguments are themselves invalid,
which keeps the helper honest: it only works when the supplied
values actually pass validation. -/
def mkTestPuzzle (repeats : Bool) (size : Nat) (letters : String)
    (mandatory : Char) (dictionary : System.FilePath) : Puzzle :=
  match validate repeats size letters mandatory dictionary with
  | Except.ok p  => p
  | Except.error errs =>
      panic! s!"mkTestPuzzle: invalid arguments: {errs}"

/-- Asserts that `actual` and `expected` are equal error lists. -/
def assertErrors (st : IO.Ref State) (actual : List String)
    (expected : List String) (msg : String) : IO Unit :=
  assertEqual st
    (toString (repr actual)) (toString (repr expected)) msg

/-- Asserts that a `validate` call succeeds and that the resulting
`Puzzle` fields match the expected values. -/
def assertValidOk (st : IO.Ref State)
    (result : Except (List String) Puzzle)
    (repeats : Bool) (size : Nat) (letters : String)
    (mandatory : Char) (dictionary : System.FilePath)
    (msg : String) : IO Unit :=
  match result with
  | Except.error errs =>
    assertEqual st (toString (repr errs)) "Except.ok _"
      s!"{msg}: expected Ok but got errors"
  | Except.ok p => do
    assertEqual st p.repeats    repeats    s!"{msg}: repeats"
    assertEqual st p.size       size       s!"{msg}: size"
    assertEqual st p.letters    letters    s!"{msg}: letters"
    assertEqual st p.mandatory  mandatory  s!"{msg}: mandatory"
    assertEqual st p.dictionary dictionary s!"{msg}: dictionary"

/-- Asserts that a `validate` call returns the given error list. -/
def assertValidErr (st : IO.Ref State)
    (result : Except (List String) Puzzle)
    (expected : List String) (msg : String) : IO Unit :=
  match result with
  | Except.ok _ =>
    assertEqual st "Except.ok _" (toString (repr expected))
      s!"{msg}: expected errors but got Ok"
  | Except.error errs =>
    assertErrors st errs expected msg

/-!
## validateSize
-/

def testValidateSize (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validateSize"

  assertErrors st (validateSize 3)
    ["Size must be between 4 and 9 (got 3)"]
    "size 3 too small"
  assertErrors st (validateSize 4) [] "size 4 ok"
  assertErrors st (validateSize 9) [] "size 9 ok"
  assertErrors st (validateSize 10)
    ["Size must be between 4 and 9 (got 10)"]
    "size 10 too large"

/-!
## validateLetters
-/

def testValidateLetters (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validateLetters"

  assertErrors st (validateLetters "abc")
    ["Letters length must be between 4 and 9 (got 3)"]
    "letters too short"
  assertErrors st (validateLetters "abcd") []
    "letters 4 ok"
  assertErrors st (validateLetters "abcdefghij")
    ["Letters length must be between 4 and 9 (got 10)"]
    "letters too long"
  assertErrors st (validateLetters "abcD")
    ["Letters must all be ASCII lowercase letters (a\u2013z)"]
    "letters uppercase"
  assertErrors st (validateLetters "abca")
    ["Letters must be unique"] "letters duplicate"
  assertErrors st (validateLetters "abcDDA")
    [
      "Letters must all be ASCII lowercase letters (a\u2013z)",
      "Letters must be unique"
    ] "letters uppercase and duplicate"
  -- C1: Unicode lowercase is now rejected.
  assertErrors st (validateLetters "ab\u00e9d")
    ["Letters must all be ASCII lowercase letters (a\u2013z)"]
    "letters unicode lowercase rejected"

/-!
## validateMandatory
-/

def testValidateMandatory (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validateMandatory"

  assertErrors st (validateMandatory 'a' "abcd") []
    "mandatory ok"
  assertErrors st (validateMandatory 'A' "abcd")
    [
      "Mandatory letter must be an ASCII lowercase letter (a\u2013z)",
      "Mandatory letter must be one of the puzzle letters"
    ] "mandatory uppercase"
  assertErrors st (validateMandatory 'z' "abcd")
    ["Mandatory letter must be one of the puzzle letters"]
    "mandatory not in letters"
  -- C1: Unicode lowercase mandatory is now rejected.
  assertErrors st (validateMandatory '\u00e9' "ab\u00e9d")
    ["Mandatory letter must be an ASCII lowercase letter (a\u2013z)"]
    "mandatory unicode lowercase rejected"

/-!
## validate (integration over all validators)
-/

def testValidate (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validate"

  let dict : System.FilePath := "dictionary"

  -- Valid input: check every field of the returned Puzzle.
  assertValidOk st
    (validate false 4 "abcd" 'a' dict)
    false 4 "abcd" 'a' dict
    "valid input"

  -- Individual field failures.
  assertValidErr st
    (validate false 3 "abcd" 'a' dict)
    ["Size must be between 4 and 9 (got 3)"]
    "size too small"

  -- Multiple errors accumulate.
  assertValidErr st
    (validate false 3 "abcD" 'a' dict)
    [
      "Size must be between 4 and 9 (got 3)",
      "Letters must all be ASCII lowercase letters (a\u2013z)"
    ]
    "multiple validation errors"

  -- Mandatory character not in letters.
  assertValidErr st
    (validate false 4 "abcd" 'z' dict)
    ["Mandatory letter must be one of the puzzle letters"]
    "mandatory letter not in letters"

  -- Mandatory character not lowercase.
  assertValidErr st
    (validate false 4 "abcd" 'A' dict)
    [
      "Mandatory letter must be an ASCII lowercase letter (a\u2013z)",
      "Mandatory letter must be one of the puzzle letters"
    ]
    "mandatory letter not lowercase"

/-!
## solve
-/

def testSolve (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.solve"

  let dict : System.FilePath := "dictionary"

  let puzzle := mkTestPuzzle false 4 "abcdefg" 'a' dict
  let words :=
    ["abcd", "abcc", "bcde", "abcdefg", "Abcd ", "xyz"]
  let expected := ["abcd", "abcdefg", "Abcd"]
  let actual := solve puzzle words

  assertEqual st
    (toString (repr actual)) (toString (repr expected))
    "solve repeats=false"

  let puzzleRepeats := mkTestPuzzle true 4 "abcdefg" 'a' dict
  let expectedRepeats := ["abcd", "abcc", "abcdefg", "Abcd"]
  let actualRepeats := solve puzzleRepeats words

  assertEqual st
    (toString (repr actualRepeats))
    (toString (repr expectedRepeats))
    "solve repeats=true"

/-!
## runPuzzle
-/

def testRunPuzzle (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.runPuzzle"

  let dict : System.FilePath := "dict.txt"
  let puzzle := mkTestPuzzle false 4 "abcdefg" 'a' dict

  -- Test 1: Success scenario.
  let ref1 ← IO.mkRef ({
    existsMap := [(dict, true)],
    fileMap := [(dict, Except.ok ["abcd", "xyz"])],
    printed := []
  } : MockFs)
  let code1 ← runPuzzle (mkMockEnv ref1) puzzle
  assertEqual st code1 0 "runPuzzle success exit code"
  let s1 ← ref1.get
  assertEqual st s1.printed ["abcd"]
    "runPuzzle success output"

  -- Test 2: Missing dictionary file.
  let ref2 ← IO.mkRef ({
    existsMap := [(dict, false)],
    fileMap := [],
    printed := []
  } : MockFs)
  let code2 ← runPuzzle (mkMockEnv ref2) puzzle
  assertEqual st code2 1
    "runPuzzle missing file exit code"
  let s2 ← ref2.get
  assertEqual st s2.printed
    ["Dictionary file does not exist"]
    "runPuzzle missing file output"

  -- Test 3: Read error.
  let ref3 ← IO.mkRef ({
    existsMap := [(dict, true)],
    fileMap := [(dict, Except.error "Permission denied")],
    printed := []
  } : MockFs)
  let code3 ← runPuzzle (mkMockEnv ref3) puzzle
  assertEqual st code3 1
    "runPuzzle read error exit code"
  let s3 ← ref3.get
  assertEqual st s3.printed
    ["Failed to read dictionary file: Permission denied"]
    "runPuzzle read error output"

/-!
## formatSolutions
-/

def testVersion (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing version extraction"
  assertEqual st appVersion "0.1.0-dev" "appVersion matches lakefile"

def testFormatSolutions (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.formatSolutions"

  assertEqual st (formatSolutions []) "No words found."
    "format empty solutions"
  assertEqual st (formatSolutions ["abcd", "xyz"]) "abcd\nxyz"
    "format non-empty solutions"

/-!
## Entry point
-/

def runTests (st : IO.Ref State) : IO Unit := do
  testValidateSize st
  testValidateLetters st
  testValidateMandatory st
  testValidate st
  testSolve st
  testRunPuzzle st
  testFormatSolutions st
  testVersion st

end Test.Basic
