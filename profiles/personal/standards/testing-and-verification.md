# Testing & Verification

The shared testing posture across projects. Language-specific mechanics (frameworks,
layout) live in the per-language conventions; this is the discipline that applies
everywhere.

## Verify Before Claiming Done

- **Run the verification command and read its output before saying something works,
  passes, or is fixed.** Evidence before assertions — always. The
  `/superpowers:verification-before-completion` skill formalizes this.
- If tests fail, say so and show the output. If a step was skipped, say that. State a
  result as done only when it's verified.
- For app-level behavior changes, drive the actual app (the `/verify` and `/run` skills)
  rather than asserting from the diff alone.

## Test-Driven Development

- For non-trivial features and bugfixes, write the failing test first
  (`/superpowers:test-driven-development`). It's a rigid workflow — don't adapt away the
  discipline.
- A bugfix gets a regression test that fails before the fix and passes after.
- Don't add a test framework or harness just to write a single test — match the project's
  existing testing approach.

## Per-Language Mechanics

- **Rust** — unit tests co-located in `#[cfg(test)] mod tests`; integration tests in
  `tests/*_e2e.rs` via `assert_cmd`; `insta` snapshots; `wiremock` for HTTP, `tempfile` for
  FS. Must be clean before commit: `cargo test`, `cargo clippy -- -D warnings`,
  `cargo fmt --check`. See `rust/conventions.md`.
- **Python** — tests under `tests/`, run via `uv`. See `python/conventions.md`.
- **JavaScript / Obsidian plugins** — mostly manual via a gitignored `test_obsidian_vault/`;
  `vitest` for pure-logic modules only. See `javascript/conventions.md`.
- **Shell** — verify against the real `/Users/local/temp/` workspace; guard destructive
  steps. See `shell/conventions.md`.

## Determinism

- Inject time and other ambient inputs so tests are reproducible — e.g., the hidden
  `--today YYYY-MM-DD` flag pattern for date-sensitive Rust CLIs (`rust/conventions.md`).
- Use fixtures and real values over mocks for internal types; reserve mocks for external
  boundaries (HTTP, FS).

## Pre-Commit Gate

Before `/git-save` commits, the project's checks must pass. Each project's `CLAUDE.md`
reproduces its exact gate commands verbatim so there's no ambiguity about what "clean"
means.

## Anti-Patterns to Avoid

- Claiming success without running the check and reading the output.
- Reporting "tests pass" when they were skipped or never run.
- Skipping the regression test on a bugfix.
- Introducing a heavyweight test framework for one trivial test.
- Mocking internal types instead of using real values or fixtures.
- Non-deterministic tests that depend on the wall clock or network without injection.
