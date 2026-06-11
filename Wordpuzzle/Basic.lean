namespace Wordpuzzle

def hello := "world"

structure Puzzle where
  repeats : Bool
  size : Nat
  letters : String
  mandatory : Char
  dictionary : System.FilePath
  deriving Repr

def validateSize (size : Nat) : Except String Unit :=
  if size < 4 || size > 9 then
    Except.error s!"Size must be between 4 and 9 (got {size})"
  else
    Except.ok ()

def validateLetters (letters : String) : Except (List String) Unit :=
  Id.run do
    let mut errs := []
    let len := letters.length
    if len < 4 || len > 9 then
      errs := s!"Letters length must be between 4 and 9 (got {len})" :: errs
    let chars := letters.toList
    if !chars.all (fun c => c.isLower) then
      let msg := "Letters must all be lowercase alphabetic characters"
      errs := msg :: errs
    let rec hasDuplicates : List Char → Bool
      | [] => false
      | c :: cs => cs.contains c || hasDuplicates cs
    if hasDuplicates chars then
      errs := "Letters must be unique" :: errs
    if !errs.isEmpty then
      Except.error errs.reverse
    else
      Except.ok ()

def validateMandatory (mandatory : Char) (letters : String) :
  Except (List String) Unit := Id.run do
  let mut errs := []
  if !mandatory.isLower then
    let msg := "Mandatory letter must be a lowercase alphabetic character"
    errs := msg :: errs
  if !letters.contains mandatory then
    let msg := "Mandatory letter must be one of the puzzle letters"
    errs := msg :: errs
  if !errs.isEmpty then
    Except.error errs.reverse
  else
    Except.ok ()

def validateDictionary (_ : System.FilePath) : Except String Unit :=
  Except.ok ()

def validate (repeats : Bool) (size : Nat) (letters : String) (mandatory : Char)
  (dictionary : System.FilePath) : Except (List String) Puzzle := Id.run do
  let mut errs := []
  match validateSize size with
  | Except.error err => errs := errs ++ [err]
  | Except.ok _ => pure ()

  match validateLetters letters with
  | Except.error lettersErrs => errs := errs ++ lettersErrs
  | Except.ok _ => pure ()

  match validateMandatory mandatory letters with
  | Except.error mandatoryErrs => errs := errs ++ mandatoryErrs
  | Except.ok _ => pure ()

  match validateDictionary dictionary with
  | Except.error err => errs := errs ++ [err]
  | Except.ok _ => pure ()

  if !errs.isEmpty then
    Except.error errs
  else
    Except.ok { repeats, size, letters, mandatory, dictionary }

def solve (puzzle : Puzzle) (dictionaryWords : List String) : List String :=
  let mandatory := puzzle.mandatory
  let rec hasNoDuplicates : List Char → Bool
    | [] => true
    | c :: cs => !cs.contains c && hasNoDuplicates cs

  let check (word : String) : Option String :=
    let cleanWord := word.trimAscii.toString
    let lowerWord := cleanWord.toLower
    if lowerWord.length >= puzzle.size &&
       lowerWord.toList.all (fun c => puzzle.letters.contains c) &&
       lowerWord.contains mandatory &&
       (puzzle.repeats || hasNoDuplicates lowerWord.toList) then
      some cleanWord
    else
      none

  dictionaryWords.filterMap check

end Wordpuzzle
