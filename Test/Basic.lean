import Wordpuzzle.Basic
import Test.Util

namespace Test.Basic

open Test.Util (assertEqual State)
open Wordpuzzle (
  validate Puzzle validateSize validateLetters validateDictionary solve
  Env runPuzzle
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

structure MockFs where
  existsMap : List (System.FilePath × Bool)
  fileMap : List (System.FilePath × Except String (List String))
  printed : List String

def mkMockEnv (ref : IO.Ref MockFs) : Env IO where
  pathExists path := do
    let s ← ref.get
    match s.existsMap.find? (fun (p, _) => p == path) with
    | some (_, b) => pure b
    | none => pure false
  readLines path := do
    let s ← ref.get
    match s.fileMap.find? (fun (p, _) => p == path) with
    | some (_, res) => pure res
    | none => pure (Except.error "File not found")
  println str := do
    ref.modify (fun s => { s with printed := s.printed ++ [str] })

def testRunPuzzle (st : IO.Ref State) : IO Unit := do
  IO.println "\n[TEST] Testing Wordpuzzle.Basic.runPuzzle"

  let dict : System.FilePath := "dict.txt"
  let puzzle := {
    repeats := false,
    size := 4,
    letters := "abcdefg",
    mandatory := 'a',
    dictionary := dict
  }

  -- Test 1: Success scenario
  let ref1 ← IO.mkRef ({
    existsMap := [(dict, true)],
    fileMap := [(dict, Except.ok ["abcd", "xyz"])],
    printed := []
  } : MockFs)
  let code1 ← runPuzzle (mkMockEnv ref1) puzzle
  assertEqual st code1 0 "runPuzzle success exit code"
  let s1 ← ref1.get
  assertEqual st s1.printed ["abcd"] "runPuzzle success output"

  -- Test 2: Missing dictionary file
  let ref2 ← IO.mkRef ({
    existsMap := [(dict, false)],
    fileMap := [],
    printed := []
  } : MockFs)
  let code2 ← runPuzzle (mkMockEnv ref2) puzzle
  assertEqual st code2 1 "runPuzzle missing file exit code"
  let s2 ← ref2.get
  assertEqual st s2.printed ["Dictionary file does not exist"]
    "runPuzzle missing file output"

  -- Test 3: Read error
  let ref3 ← IO.mkRef ({
    existsMap := [(dict, true)],
    fileMap := [(dict, Except.error "Permission denied")],
    printed := []
  } : MockFs)
  let code3 ← runPuzzle (mkMockEnv ref3) puzzle
  assertEqual st code3 1 "runPuzzle read error exit code"
  let s3 ← ref3.get
  assertEqual st s3.printed
    ["Failed to read dictionary file: Permission denied"]
    "runPuzzle read error output"

def runTests (st : IO.Ref State) : IO Unit := do
  testValidateSize st
  testValidateLetters st
  testValidateDictionary st
  testValidate st
  testSolve st
  testRunPuzzle st

end Test.Basic
