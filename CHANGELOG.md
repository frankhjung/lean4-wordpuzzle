# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0-dev [Unreleased]

### Added

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

- Removed the `validateDictionary` pure validation stub as dictionary existence
  is correctly handled at runtime by `Env.pathExists`.
- Removed `mkPuzzleForTest` unsafe constructor from the public API.
