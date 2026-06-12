import Wordpuzzle.Basic

namespace Test.Util

structure State where
  fails : Nat
  total : Nat

def mkState : IO (IO.Ref State) :=
  IO.mkRef { fails := 0, total := 0 }

def assertEqual {α : Type} [BEq α] [ToString α] (st : IO.Ref State) (actual : α) (expected : α) (msg : String) : IO Unit := do
  let s ← st.get
  let total := s.total + 1
  if actual == expected then
    st.set { s with total := total }
    IO.println s!"[PASS] {msg}"
  else
    st.set { s with total := total, fails := s.fails + 1 }
    IO.println s!"[FAIL] {msg}: expected {expected}, got {actual}"

def assertTrue (st : IO.Ref State) (actual : Bool) (msg : String) : IO Unit := do
  assertEqual st actual true msg

def summary (st : IO.Ref State) : IO Unit := do
  let s ← st.get
  IO.println ""
  IO.println s!"[TEST] Summary: {s.total} tests, {s.fails} failures"

structure MockFs where
  existsMap : List (System.FilePath × Bool)
  fileMap : List (System.FilePath × Except String (List String))
  printed : List String

def mkMockEnv (ref : IO.Ref MockFs) : Wordpuzzle.Env IO where
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

end Test.Util
