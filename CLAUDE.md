# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Local Upload — a pomf-compatible file host built with Phoenix/Elixir
and SQLite. Event-sourced: the append-only `events` table in SQLite is
the single source of truth. Everything else (uploads, comments, votes)
is a derived projection held in ETS tables.

## Commands

- `mix precommit` — compile (warnings-as-errors), unlock unused deps, format, test, dialyzer
- `mix test test/examples_test.exs` — run example-based tests only
- `mix test --only http` — run HTTP-dependent tests
- `timeout 60 mix run -e 'EUpload.create_upload()'` — run a single example (never `--no-halt`)
- `mix format` — 98 char line length

## Architecture

```
Write:  Controller → Context → EventStore.append() → SQLite INSERT → ProjectionStore.project() → ETS
Read:   Controller → Context → ETS (direct read, no GenServer)
Boot:   Repo → Migrator → ProjectionStore (replays all events into ETS) → Endpoint
```

**EventStore** (`event_store.ex`) is the only write interface.
`append/1` inserts into SQLite, then synchronously calls
`ProjectionStore.project/1`.

**ProjectionStore** (`projection_store.ex`) is a GenServer owning
three ETS tables (`:local_upload_uploads`, `_comments`, `_votes`).
Writes serialize through the GenServer; reads hit ETS directly.
A watermark prevents re-projecting seen events. On boot it replays
all events before the endpoint accepts requests.

**Event types**: `file_uploaded`, `comment_added`, `vote_cast`,
`file_deleted` (masking event — removes upload + comments + votes
from ETS). Deduplication (upload hash, vote per IP) is enforced at
the projection layer, not the event log.

**Contexts** — `Uploads`, `Comments`, `Votes` — each read ETS
directly and write through `EventStore.append/1`.

**Web layer** — no LiveViews, server-rendered HTML. Three router scopes:
pomf API (`POST /upload.php`, JSON, no CSRF), file serving
(`GET /f/:name`, no middleware), and browser (all other routes,
with `IPHash` and `Auth` plugs). Auth is session-based, gated by
optional `upload_secret` config. Files stored in `priv/uploads/`,
deleted with `shred`.

**Examples** live in `lib/examples/e_<module>.ex` (module `E<Module>`),
use `ExExample` with `assert` from `ExUnit.Assertions`. Composable —
examples call each other. Tested via `test/examples_test.exs`.

## Git Conventions

@.claude/skills/git-conventions/SKILL.md

## Elixir Conventions

@.claude/skills/elixir-conventions/SKILL.md

## General Conventions

@.claude/skills/general-conventions/SKILL.md
