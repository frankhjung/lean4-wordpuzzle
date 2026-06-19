# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0-dev [Unreleased]

### Added

- Added `viewdoc` target in `Makefile` to view generated documentation locally.
- Added application version constant in `Wordpuzzle/Config.lean` to bake the
  version string directly into the executable, ensuring it remains fully
  standalone.
- Added `isAsciiLower` guard to strictly enforce ASCII lowercase (`a`–`z`)
  letters during puzzle validation, correctly rejecting Unicode lowercase
  characters (e.g. `é`).
- Added `Inhabited` derivation to the `Puzzle` structure to support test-time
  panics.
- Expanded `GLOSSARY.md` with new domain terms: Capability Interface, Letters,
  Repeats, and Smart Constructor.

### Changed

- Corrected and updated inline documentation for the `solve` function in
  `Wordpuzzle/Basic.lean` and the `mkTestPuzzle` helper in `Test/Basic.lean`
  to fix typos and align with the signature refactoring.
- Updated `GLOSSARY.md` to adhere to Markdown heading standards (using H2/H3
  headings) and added a definition for the nested `docbuild` directory.
- Refactored the solver to stream the dictionary file line-by-line using
  `IO.FS.Handle` rather than loading the entire dictionary list in memory.
- Simplified package structure: made `Wordpuzzle/Basic.lean` pure by removing
  the polymorphic capability interface (`Env`) and moving all console I/O
  and file streaming to the boundary in `Wordpuzzle.lean`.
- Updated the unit test suite to test pure validation and single-word solver
  logic, eliminating mock environments and environment runners.
- Switched the GitHub Actions documentation workflow (`lean_action_ci.yml`)
  to use the official `leanprover-community/docgen-action`.
- Upgraded Lean toolchain to `v4.31.0`.
- Improved `Makefile` error handling to explicitly report if Lean is not found
  in `PATH`.
- Migrated lint driver to `batteries/runLinter`.
- Updated `lint` target in `Makefile` to include the `--lint-all` flag.
- Updated `README.md` to include commands for opening generated documentation in
  a web browser.
- Refactored `solve` to bind string-to-list conversions once per word and
  hoist invariant puzzle characters, improving search performance.
- Pinned `Cli` dependency to a specific commit hash in `lakefile.toml` to
  ensure reproducible builds.
- Updated `README.md` with a detailed project structure tree, updated Elan
  installation instructions, and a CLI flags table.
- Test suites now use a local `mkTestPuzzle` helper that validates and panics
  on bad arguments, removing the need for an unsafe constructor in the core
  module.

### Removed

- Removed the `Env` capability interface, `runPuzzle` runner, and
  `formatSolutions` helper from `Wordpuzzle/Basic.lean`.
- Removed `realEnv` from `Wordpuzzle.lean`.
- Removed `MockFs` and `mkMockEnv` from `Test/Util.lean`.
- Removed custom `linter` executable in favor of `batteries/runLinter`.
- Removed the `validateDictionary` pure validation stub as dictionary existence
  is correctly handled at runtime by `Env.pathExists`.
- Removed `mkPuzzleForTest` unsafe constructor from the public API.
