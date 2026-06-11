import Test.Basic
import Test.Util

open Test.Util (mkState summary)

def main : IO Unit := do
  IO.println "Running tests..."

  let st ← mkState
  Test.Basic.runTests st

  summary st
  let s ← st.get
  if s.fails > 0 then
    IO.println "[TEST] Some tests failed."
    IO.Process.exit 1
  else
    IO.println "[TEST] All tests passed!"
