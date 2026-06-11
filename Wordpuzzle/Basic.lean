namespace Wordpuzzle

structure Puzzle where
  private mk ::
  repeats : Bool
  size : Nat
  letters : String
  mandatory : Char
  dictionary : System.FilePath
  deriving Repr

/-- Unsafe constructor helper for testing purposes. -/
def mkPuzzleForTest (repeats : Bool) (size : Nat) (letters : String)
  (mandatory : Char) (dictionary : System.FilePath) : Puzzle :=
  { repeats, size, letters, mandatory, dictionary }

def hasDuplicates {α : Type} [BEq α] : List α → Bool
  | [] => false
  | x :: xs => xs.contains x || hasDuplicates xs

def validateSize (size : Nat) : List String :=
  if size < 4 || size > 9 then
    [s!"Size must be between 4 and 9 (got {size})"]
  else
    []

def validateLetters (letters : String) : List String :=
  let len := letters.length
  let chars := letters.toList
  let conds := [
    (len < 4 || len > 9,
     s!"Letters length must be between 4 and 9 (got {len})"),
    (!chars.all (fun c => c.isLower),
     "Letters must all be lowercase alphabetic characters"),
    (hasDuplicates chars,
     "Letters must be unique")
  ]
  conds.filterMap (fun (cond, msg) => if cond then some msg else none)

def validateMandatory (mandatory : Char) (letters : String) : List String :=
  let conds := [
    (!mandatory.isLower,
     "Mandatory letter must be a lowercase alphabetic character"),
    (!letters.contains mandatory,
     "Mandatory letter must be one of the puzzle letters")
  ]
  conds.filterMap (fun (cond, msg) => if cond then some msg else none)

def validateDictionary (_ : System.FilePath) : List String :=
  []

def validate (repeats : Bool) (size : Nat) (letters : String)
  (mandatory : Char) (dictionary : System.FilePath) :
  Except (List String) Puzzle :=
  let errs := validateSize size ++
              validateLetters letters ++
              validateMandatory mandatory letters ++
              validateDictionary dictionary
  if errs.isEmpty then
    Except.ok { repeats, size, letters, mandatory, dictionary }
  else
    Except.error errs

def solve (puzzle : Puzzle) (dictionaryWords : List String) : List String :=
  let mandatory := puzzle.mandatory
  let check (word : String) : Option String :=
    let cleanWord := word.trimAscii.toString
    let lowerWord := cleanWord.toLower
    if lowerWord.length >= puzzle.size &&
       lowerWord.toList.all (fun c => puzzle.letters.contains c) &&
       lowerWord.contains mandatory &&
       (puzzle.repeats || !hasDuplicates lowerWord.toList) then
      some cleanWord
    else
      none

  dictionaryWords.filterMap check

structure Env (m : Type → Type) where
  pathExists : System.FilePath → m Bool
  readLines  : System.FilePath → m (Except String (List String))
  println    : String → m Unit

def runPuzzle [Monad m] (env : Env m) (puzzle : Puzzle) : m UInt32 := do
  if !(← env.pathExists puzzle.dictionary) then
    env.println "Dictionary file does not exist"
    return 1
  match ← env.readLines puzzle.dictionary with
  | Except.error err =>
    env.println s!"Failed to read dictionary file: {err}"
    return 1
  | Except.ok lines =>
    let solutions := solve puzzle lines
    if solutions.isEmpty then
      env.println "No words found."
    else
      for w in solutions do
        env.println w
    return 0

end Wordpuzzle
