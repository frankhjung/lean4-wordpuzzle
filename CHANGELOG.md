# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Adjusted `docgen-action` configuration to disable page building
  (`build-page: false`) in both the documentation and release workflows for
  improved build efficiency.
- Refined linting target in `Makefile` to lint only the `Wordpuzzle` package
  (`--lint-only Wordpuzzle`) instead of linting all packages (`--lint-all`).
- Fixed toolchain in `docbuild/lake-manifest.json` to use a fixed toolchain for
  reproducible documentation builds.

## [0.1.0] - 2026-06-26

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
- Added unit tests for the all-six-error validation boundary, the repeats
  validation configuration, and the short-word edge case in solver checks.
- Added automated GitHub Releases creation for tagged workflow runs, attaching
  built executable and documentation binaries.

### Changed

- Pinned docgen-action to a specific commit SHA in lean_action_ci.yml to ensure
  reproducible documentation builds.
- Refactored CI workflow permissions to enforce the principle of least privilege
  by disabling global permissions and specifying them per job.
- Fixed GitHub Pages deployment issues by removing redundant artifact upload and
  deploy steps.
- Fixed typechecking error in the Validated namespace in Wordpuzzle/Basic.lean
  by adding implicit type variable binders.
- Updated markdown documentation file links in GLOSSARY.md and other files to
  use repo-relative paths instead of absolute local file links.
- Cleaned up `Test/Util.lean` by removing unused import `Wordpuzzle.Basic` and
  the redundant `assertTrue` helper.
- Fixed stale line anchors in `README.md` and `GLOSSARY.md`.
- Refactored `Puzzle` structure to embed mathematical proof fields ensuring
  correctness-by-construction (e.g., `h_size`, `h_letters_unique`).
- Updated CLI adapter to use the `require!` extension, making the `--letters`
  and `--mandatory` flags strictly mandatory.
- Reordered declarations to improve logical flow and dependency order.
- Corrected and updated inline documentation for the `solve` function in
  `Wordpuzzle/Basic.lean` and the `mkTestPuzzle` helper in `Test/Basic.lean` to
  fix typos and align with the signature refactoring.
- Updated `GLOSSARY.md` to adhere to Markdown heading standards (using H2/H3
  headings) and added a definition for the nested `docbuild` directory.
- Refactored the solver to stream the dictionary file line-by-line using
  `IO.FS.Handle` rather than loading the entire dictionary list in memory.
- Simplified package structure: made `Wordpuzzle/Basic.lean` pure by removing
  the polymorphic capability interface (`Env`) and moving all console I/O and
  file streaming to the boundary in `Wordpuzzle.lean`.
- Updated the unit test suite to test pure validation and single-word solver
  logic, eliminating mock environments and environment runners.
- Switched the GitHub Actions documentation workflow (`lean_action_ci.yml`) to
  use the official `leanprover-community/docgen-action`.
- Upgraded Lean toolchain to `v4.31.0`.
- Improved `Makefile` error handling to explicitly report if Lean is not found
  in `PATH`.
- Migrated lint driver to `batteries/runLinter`.
- Updated `lint` target in `Makefile` to include the `--lint-all` flag.
- Updated `README.md` to include commands for opening generated documentation in
  a web browser.
- Refactored `solve` to bind string-to-list conversions once per word and hoist
  invariant puzzle characters, improving search performance.
- Pinned `Cli` dependency to a specific commit hash in `lakefile.toml` to ensure
  reproducible builds.
- Updated `README.md` with a detailed project structure tree, updated Elan
  installation instructions, and a CLI flags table.
- Test suites now use a local `mkTestPuzzle` helper that validates and panics on
  bad arguments, removing the need for an unsafe constructor in the core module.

### Removed

- Removed the `Env` capability interface, `runPuzzle` runner, and
  `formatSolutions` helper from `Wordpuzzle/Basic.lean`.
- Removed `realEnv` from `Wordpuzzle.lean`.
- Removed `MockFs` and `mkMockEnv` from `Test/Util.lean`.
- Removed custom `linter` executable in favor of `batteries/runLinter`.
- Removed the `validateDictionary` pure validation stub as dictionary existence
  is correctly handled at runtime by `Env.pathExists`.
- Removed `mkPuzzleForTest` unsafe constructor from the public API.
