# Refactor Wordpuzzle

I want to refactor Wordpuzzle to be simpler. At the moment it loads the
dictionary into a list, then processes that list.

## Refactor Plan

Instead I'd like to have the main function `Wordpuzzle.lean` to:

- dictionary is not required by the `Puzzle` structure
- check commandline arguments (as it does curently) using validation function
  calls in the `Wordpuzzle/Basic.lean` module
  - print all error messages at once, exit with code 1 otherwise continue
- read the dictionary as a stream of words
- filter each word via a `solve` function in `Wordpuzzle/Basic.lean` with
  arguments:
  - the `Puzzle` structure
  - the current dictionary "word"
  - then - print the word on success
  - continue until end of dictionary
- the function `solve` in `Wordpuzzle/Basic.lean` needs only two parameters:
  1. the `Puzzle` structure
  2. the current dictionary "word"
  - the function should return an `Option String`:
    1. `Some word` on success
    2. `none` on failure

## Notes

- The functions in the `Wordpuzzle/Basic.lean` module should be pure.
- The only IO should occur in `Wordpuzzle/Basic.lean`
- Update the tests to match the new implementation
- We should not need the `realEnv` function as we now stream in main
- Run `make` targets `build`, `lint` and `test` to verify changes

## Executed Implementation Plan

This refactoring was executed successfully with the following design choices
and tasks:

### Design Decisions Resolved

1. **IO Location**: All IO resides in [Wordpuzzle.lean][wp-main], keeping
   [Basic.lean][wp-basic] pure.
2. **Dictionary Validation**: The CLI validation (pure) runs first. If it
   succeeds, the dictionary file existence check runs in the `IO` monad in
   [Wordpuzzle.lean][wp-main].
3. **Empty Results**: If no matching words are found in the dictionary, "No
   words found." is printed.
4. **Testing**: Adapted tests to verify the pure validation and single-word
   `solve` function, relying on integration/make targets for streaming.

### Tasks Completed

1. **Update Basic.lean**:
   - Removed `dictionary : System.FilePath` from the `Puzzle` structure.
   - Updated `validate` to remove the `dictionary` parameter.
   - Refactored `solve` to take `(puzzle : Puzzle) (word : String)` and
     return `Option String`.
   - Removed the `Env` structure, `formatSolutions`, and `runPuzzle`.
2. **Update Wordpuzzle.lean**:
   - Updated imports and command handler to match the new `validate`
     signature.
   - Implemented pure validation checks, printing errors and exiting with
     code 1 if they fail.
   - Implemented dictionary file existence check in IO.
   - Streamed dictionary line-by-line using `IO.FS.Handle.mk` and a recursive
     `streamPuzzle` helper function.
   - Tracked whether any words were found, and printed "No words found." if
     the dictionary finished with no matches.
3. **Update Tests**:
   - Updated [Test/Util.lean][test-util] to remove `MockFs` and `mkMockEnv`.
   - Updated [Test/Basic.lean][test-basic] to remove the `dictionary`
     parameter from `mkTestPuzzle` and `testValidate`, rewrite `testSolve` to
     test individual words, and remove `testRunPuzzle`/`testFormatSolutions`.
4. **Update CI Workflow**:
   - Replaced the manual documentation compilation steps in
     [lean_action_ci.yml][ci-wf] with the official `docgen-action`.
   - Consolidated the `docs` and `pages` jobs into a single `docs` job.

[wp-main]: file:///home/frank/dev/lean/wordpuzzle/Wordpuzzle.lean
[wp-basic]: file:///home/frank/dev/lean/wordpuzzle/Wordpuzzle/Basic.lean
[test-util]: file:///home/frank/dev/lean/wordpuzzle/Test/Util.lean
[test-basic]: file:///home/frank/dev/lean/wordpuzzle/Test/Basic.lean
[ci-wf]: file:///home/frank/dev/lean/wordpuzzle/.github/workflows/lean_action_ci.yml

## Executed Validation Refactoring Plan

This refactoring was executed successfully with the following
design choices and tasks:

### Design Decisions Resolved

1. **Accumulate-then-redecide**:
   Each validator returns `List String` error messages. The
   `validate` smart constructor concatenates all error lists,
   then performs a single pass of nested decidable `if h :` checks
   to extract the six proof witnesses required by `Puzzle`. When
   no errors are present the decidable checks are guaranteed to
   succeed.
2. **Split validators**:
   Separated multi-concern validators into six single-purpose
   helpers (`validateSize`, `validateLettersLen`, etc.) to
   enforce single-responsibility and exact structural mapping to
   `Puzzle` invariants. Each validator checks the same decidable
   proposition used by the corresponding `Puzzle` proof field.
3. **Stable interface**:
   Maintained the public interface signature
   `Except (List String) Puzzle` for the `validate` function,
   preventing cascading changes in `Wordpuzzle.lean` and
   integration tests.

### Tasks Completed

1. **Refactor Basic.lean**:
   - Replaced old combined validators with six single-purpose
     helpers returning `List String`.
   - Refactored `validate` to accumulate errors then re-decide
     for proof extraction.
2. **Refactor Tests**:
   - Updated `Test/Basic.lean` test assertions to work with
     `List String` returns (`assertNoErrors`, `assertHasErrors`).
   - Replaced the old combined validator tests with separate
     unit tests for the six new validator helpers.
3. **Update Documentation**:
   - Updated `GLOSSARY.md` and `docs/refactor.md` to document
     the simplified validation approach.
