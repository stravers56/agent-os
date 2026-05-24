# Project Structure & Working Discipline

Cross-cutting conventions for how projects are laid out, documented, and remembered, plus
how Claude should work within them. Language-specific layouts live in the per-language
conventions; this is the shared baseline.

## Local Layout

Projects live under `/Users/local/` by language (`$HOME`-independent; the layout is stable
across machines):

- `python/`, `rust/`, `javascript/`, `scripts/`, `latex/`, `latex-templates/`,
  `obsidian/`, `misc/`, `datafiles/`, `ghforks/` (modifiable forks), `templates/`.
- **Temp/scratch: always `/Users/local/temp/`** — git-tracked, syncs across machines; never
  `/tmp` or `$TMPDIR` (per global `CLAUDE.md`). Python `tempfile(dir="/Users/local/temp")`;
  shell `mktemp -p /Users/local/temp`.

## Every Project Has Two Docs

- **`README.md`** — user-facing: what it is, how to install/run.
- **`CLAUDE.md`** — Claude-facing: build/test commands verbatim, project structure, key
  invariants, valid enum values, hidden test flags, known gaps. This is the per-project
  source of truth Claude reads first.

Keep both current as part of `/git-save`.

## Project Memory

For repos under the qualifying roots (`/Users/local/{javascript,latex,latex-templates,
misc,obsidian,python,rust}/*` and `/Users/local/scripts/`), `type: project` memories live
**in the repo**, not in user-scope memory, so they sync via the project's own remote:

1. `<project-root>/.claude/memory/<file>.md` — full memory files with frontmatter, plus a
   `MEMORY.md` index in the same directory.
2. `<project-root>/CLAUDE.md` — a "Project Memory" section referencing those files so any
   session opening the project picks them up.

Rules: only `type: project` memories go in-repo (`user`/`feedback`/`reference` stay
user-scope, and durable cross-cutting guidance prefers a **skill** over memory). Never write
secrets or unaliasable user-home paths into project memory. Ensure `.claude/memory/` is not
gitignored. See the global `CLAUDE.md` for the full migration/symlink rules.

## Scaffolding a New Project

- Use the most specific template available and copy the whole directory (LaTeX projects:
  `/Users/local/latex-templates/`; the `.gitignore`, `.claude/`, and `CLAUDE.md` are part
  of the contract — don't cherry-pick).
- Start `CLAUDE.md` and `README.md` from the start, not after the fact.
- Set up the project `.gitignore` to exclude artifacts/secrets before the first commit
  (see `git-workflow.md`, `security.md`).

## Working Discipline

How Claude should operate in these projects (reinforces the global `CLAUDE.md` and the
`/steven-profile` skill):

- **Ask clarifying questions before starting non-trivial work** — scope, output format,
  affected files/systems, whether to commit/push, ambiguous terms. Keep questions concise
  and numbered. Proceed without asking only on unambiguous direct commands ("compile the
  document", "run the tests") or follow-ups within an already-clarified task.
- **Brainstorm before creative work** (`/superpowers:brainstorming`) — explore intent and
  design before building a new feature or component.
- **Plan multi-step work before touching code** (`/superpowers:writing-plans`, or
  `/shape-spec` in plan mode for spec-worthy work).
- **Scope discipline** — do what was asked; surface adjacent issues rather than silently
  expanding scope. "Do the rest" of an in-progress task means finish it now, not defer it.
- **Verify before claiming done** (see `testing-and-verification.md`).
- **Prefer institutional knowledge first** — `obsearch`/`obsearchf` against the calliope
  vault, then the project's own `research/`, then the web (see `obsidian/conventions.md`).

## Anti-Patterns to Avoid

- A project without a `CLAUDE.md` (Claude has no source of truth for build/test/invariants).
- Scratch files in `/tmp` instead of `/Users/local/temp/`.
- Project memory written to user-scope when the repo qualifies for in-repo memory.
- Secrets or unaliasable user-home paths in `CLAUDE.md` or project memory.
- Starting non-trivial work without clarifying scope and output.
- Expanding scope beyond what was asked instead of surfacing the adjacent issue.
