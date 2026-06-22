import Wordpuzzle.Basic

namespace Test.Util

/-- Mutable state for the test runner tracking passes and failures. -/
structure State where
  fails : Nat
  total : Nat

/-- Creates a new initialised test runner state. -/
def mkState : IO (IO.Ref State) :=
  IO.mkRef { fails := 0, total := 0 }

def assertEqual {α : Type} [BEq α] [ToString α]
    (st : IO.Ref State) (actual : α) (expected : α)
    (msg : String) : IO Unit := do
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

/-- Prints a summary of the test results to standard output. -/
def summary (st : IO.Ref State) : IO Unit := do
  let s ← st.get
  IO.println ""
  IO.println s!"[TEST] Summary: {s.total} tests, {s.fails} failures"

end Test.Util

