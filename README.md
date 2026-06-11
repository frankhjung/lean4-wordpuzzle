# Word Puzzle Solver

A Lean 4 implementation of the Word Puzzle Solver algorithm.

## About

The **Word Puzzle Solver** is an simple solving word puzzles where you are given a set of letters and must form words that contain the mandatory
character and are at least _n_ characters long. For example: this solves [New York Times Spelling Bee](https://www.nytimes.com/puzzles/spelling-bee).

## Installation

This project requires Lean 4. You can install it using [Elan](https://github.com/leanprover/elan).

**Linux/macOS:**

```bash
curl https://raw.githubusercontent.com/leanprover/elan/master/toolchain.sh | sh
```

## Usage

To run the project:

```bash
lake env lean --run Wordpuzzle.lean
```

The program will execute the word puzzle solver and print the solution
to the console.

## Development

To work on the project:

```bash
# Build the project
lake build

# Run tests (if any)
lake test
```

### Project Structure

- `Wordpuzzle.lean`: Contains the main logic and solver.
- `lakefile.toml`: Build configuration for Lake (Lean's package manager).

## License

This project is licensed under the [BSD 2-Clause License](LICENSE).
