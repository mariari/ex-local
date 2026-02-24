# CLAUDE.md

## Project

Local Upload — a pomf-compatible file host built with Phoenix/Elixir.
Event-sourced: append-only event log is essential state, everything
else (uploads, comments, votes) is a derived projection.

## Commands

- `mix precommit` — compile (warnings-as-errors), format, test, dialyzer
- `timeout 60 mix run -e 'code'` — run one-off expressions (never `--no-halt`)
- `mix format` — 98 char line length

## Git Conventions

- **Topics branch off the latest release tag**, not main/next.
- **Topics merge individually into master** for release (`--no-ff`).
  Never merge `next` into master.
- **next** is for integration testing only — not a release source.
- One concern per topic. Name: `name/description`.
- Base bug fixes on the introducing commit (`git blame`).
- Merge dependencies into your topic, don't rebase onto main.
- No evil merges — conflict resolution only; extra changes go in
  a separate `evil!` commit.

## Elixir Conventions

- `with` chains over nested `case`.
- Pattern match in function heads, not body branches.
- `typedstruct` for structs; union types for option lists.
- GenServer: core logic in `do_` functions, never call callbacks
  from callbacks. Organize into Public API / Callbacks / Private
  sections with banner comments.
- `@moduledoc` in first person: "I am the X module."
- All public functions get `@doc` and `@spec`.
- Examples live in `lib/examples/e_<module>.ex`, module name `E<Module>`.
- Use `import ExUnit.Assertions` for `assert` in examples.

## General Conventions

- Minimize code. No abstractions for single use.
- Generalize, don't special-case.
- Dead code is noise — remove it.
- Cross-module data should be typed structures.
- Higher-level functions before lower-level helpers.
- Run examples and inspect state before writing or reviewing code.
- Every changed line traces to the request. No unasked improvements.
- Stop after 2 failed attempts — diagnose, don't brute-force.
- Restate the task and surface assumptions before starting work.
