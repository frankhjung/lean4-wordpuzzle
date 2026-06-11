import Wordpuzzle.Basic
import Test.Util

namespace Test.Basic

open Test.Util (assertEqual State)
open Wordpuzzle (
  validate Puzzle validateSize validateLetters validateDictionary solve
)

def assertValidation (st : IO.Ref State) (actual : Except (List String) Puzzle)
  (expected : Except (List String) Puzzle) (msg : String) : IO Unit := do
  assertEqual st (toString (repr actual)) (toString (repr expected)) msg

def assertErrors (st : IO.Ref State) (actual : List String)
  (expected : List String) (msg : String) : IO Unit := do
  assertEqual st (toString (repr actual)) (toString (repr expected)) msg

def testValidateSize (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validateSize"

  assertErrors st (validateSize 3)
    ["Size must be between 4 and 9 (got 3)"] "size 3 too small"
  assertErrors st (validateSize 4) [] "size 4 ok"
  assertErrors st (validateSize 9) [] "size 9 ok"
  assertErrors st (validateSize 10)
    ["Size must be between 4 and 9 (got 10)"] "size 10 too large"

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
    ["Letters must all be lowercase alphabetic characters"]
    "letters uppercase"
  assertErrors st (validateLetters "abca")
    ["Letters must be unique"] "letters duplicate"
  assertErrors st (validateLetters "abcDDA")
    [
      "Letters must all be lowercase alphabetic characters",
      "Letters must be unique"
    ] "letters uppercase and duplicate"

def testValidateDictionary (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validateDictionary"

  let dict : System.FilePath := "dictionary"
  assertErrors st (validateDictionary dict) []
    "dictionary ok"

def testValidate (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.validate"

  let dict : System.FilePath := "dictionary"

  -- Test 1: Valid input
  assertValidation st
    (validate false 4 "abcd" 'a' dict)
    (Except.ok {
      repeats := false,
      size := 4,
      letters := "abcd",
      mandatory := 'a',
      dictionary := dict
    })
    "valid input"

  -- Test 2: Size too small
  assertValidation st
    (validate false 3 "abcd" 'a' dict)
    (Except.error ["Size must be between 4 and 9 (got 3)"])
    "size too small"

  -- Test 3: Multiple errors
  assertValidation st
    (validate false 3 "abcD" 'a' dict)
    (Except.error [
      "Size must be between 4 and 9 (got 3)",
      "Letters must all be lowercase alphabetic characters"
    ])
    "multiple validation errors"

  -- Test 4: Mandatory character not in letters
  assertValidation st
    (validate false 4 "abcd" 'z' dict)
    (Except.error ["Mandatory letter must be one of the puzzle letters"])
    "mandatory letter not in letters"

  -- Test 5: Mandatory character not lowercase
  assertValidation st
    (validate false 4 "abcd" 'A' dict)
    (Except.error [
      "Mandatory letter must be a lowercase alphabetic character",
      "Mandatory letter must be one of the puzzle letters"
    ])
    "mandatory letter not lowercase"

def testSolve (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.solve"

  let dict : System.FilePath := "dictionary"
  let puzzle := {
    repeats := false,
    size := 4,
    letters := "abcdefg",
    mandatory := 'a',
    dictionary := dict
  }

  let words := ["abcd", "abcc", "bcde", "abcdefg", "Abcd ", "xyz"]
  let expected := ["abcd", "abcdefg", "Abcd"]
  let actual := solve puzzle words

  assertEqual st (toString (repr actual)) (toString (repr expected))
    "solve repeats=false"

  let puzzleRepeats := {
    repeats := true,
    size := 4,
    letters := "abcdefg",
    mandatory := 'a',
    dictionary := dict
  }
  let expectedRepeats := ["abcd", "abcc", "abcdefg", "Abcd"]
  let actualRepeats := solve puzzleRepeats words

  assertEqual st (toString (repr actualRepeats)) (toString (repr expectedRepeats))
    "solve repeats=true"

def runTests (st : IO.Ref State) : IO Unit := do
  testValidateSize st
  testValidateLetters st
  testValidateDictionary st
  testValidate st
  testSolve st

end Test.Basic
