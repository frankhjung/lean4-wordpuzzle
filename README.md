# Word Puzzle Solver

A Lean 4 implementation of a word puzzle solver.

## About

The **Word Puzzle Solver** is a simple solver for word puzzles where you
are given a set of letters and must form words that contain the mandatory
character and are at least _n_ characters long. For example, this solves
the [New York Times Spelling Bee](https://www.nytimes.com/puzzles/spelling-bee).

## Installation

This project requires Lean 4. You can install it using
[Elan](https://github.com/leanprover/elan).

**Linux/macOS:**

```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/toolchain.sh | sh
```

## Usage

To run the project, use the provided `Makefile` utility target:

```bash
make exe
```

This will run the executable with a sample word puzzle. Alternatively, run
the binary directly using Lake:

```bash
lake exe wordpuzzle -s 7 -m c -l cadevrsoi
```

## Development

A `Makefile` is provided to simplify development and testing targets.

```bash
# Build the project
make build

# Run the unit test suite
make test

# Run the linter
make lint

# Generate documentation
make doc
```

### Project Structure

- `Wordpuzzle.lean`: The entry point and command-line interface adapter.
- `Wordpuzzle/Basic.lean`: The core solver logic, smart constructors,
  validation rules, and capability interfaces.
- `Test/Basic.lean`: Unit tests for the validation, solver, and runner.
- `lakefile.toml`: Build configuration for Lake (Lean's package manager).

## License

This project is licensed under the [BSD 2-Clause License](LICENSE).
