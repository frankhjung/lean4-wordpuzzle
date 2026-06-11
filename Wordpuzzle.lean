import Cli
import Wordpuzzle.Basic

open Cli
open Wordpuzzle (validate solve)

instance : ParseableType System.FilePath where
  name := "FilePath"
  parse? s := some ⟨s⟩

instance : ParseableType Char where
  name := "Char"
  parse? s := if s.length == 1 then some s.front else none

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
    if !(← System.FilePath.pathExists puzzle.dictionary) then
      IO.println "Dictionary file does not exist"
      return 1
    try
      let dictionaryLines ← IO.FS.lines puzzle.dictionary
      let solutions := solve puzzle dictionaryLines.toList
      if solutions.isEmpty then
        IO.println "No words found."
      else
        for w in solutions do
          IO.println w
      return 0
    catch e =>
      IO.println s!"Failed to read dictionary file: {e}"
      return 1

def wordpuzzleCmd : Cmd := `[Cli|
  wordpuzzleCmd VIA runWordpuzzleCmd; ["0.1.0"]
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

def main (args : List String) : IO UInt32 :=
  wordpuzzleCmd.validate args
