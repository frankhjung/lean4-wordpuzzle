import Lean

open Lean Elab Term

namespace Wordpuzzle

def removeQuotes (s : String) : String :=
  let chars := s.toList
  match chars with
  | '"' :: rest =>
    match rest.reverse with
    | '"' :: rest' => String.ofList rest'.reverse
    | _ => s
  | _ => s

/-- Extracts the version string from lakefile.toml at compile time. -/
elab "lakefileVersion%" : term => do
  let content ← IO.FS.readFile "lakefile.toml"
  let lines := content.splitOn "\n"
  for line in lines do
    let line := line.trimAscii.toString
    if line.startsWith "version" then
      let parts := line.splitOn "="
      if parts.length >= 2 then
        let ver := parts[1]!.trimAscii.toString
        let ver := removeQuotes ver
        return mkStrLit ver
  throwError "version not found in lakefile.toml"

/-- The version of the application, resolved at compile time. -/
def appVersion : String := lakefileVersion%
