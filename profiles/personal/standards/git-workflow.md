# Git Workflow

Applies to every project regardless of language. The `/git-save` skill is the
authoritative procedure for saving work — this standard records the conventions it
enforces so they're available even when the skill isn't loaded.

## Saving Work

Use the `/git-save` skill when asked to save, commit, or push. It runs tests, updates
`CLAUDE.md` / `README.md` / `CHANGELOG`, commits, pushes when a remote exists, checks
Dependabot alerts, and suggests tags. Don't hand-roll the commit dance when the skill
applies.

## Commit Discipline

- **Commit or push only when asked.** Don't auto-commit after making changes.
- **Branch before committing on the default branch.** If on `main`/`master`, create a
  feature branch first rather than committing directly.
- One logical change per commit; write messages that explain *why*, not just *what*.
- End every commit message with the co-author trailer:
  ```
  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
  ```
- Interactive git flags (`git rebase -i`, `git add -i`) don't work in this environment —
  use non-interactive equivalents.

## GitHub

- Use the `gh` CLI (or the `github` MCP server) for PRs, issues, and API operations.
- End PR bodies with the Claude Code attribution line.
- `ghcreaterepo.zsh` (`$scripts`) scaffolds new GitHub repos.

## Multi-Repo Sync

- `pushall` / `pullall` (`$scripts`) sync the working set of repos across machines,
  including `~/.claude/` (skills + global memory) and `/Users/local/temp/`.
- `~/.claude/` is git-synced; **per-project memory under `~/.claude/projects/*/memory/` is
  gitignored and local-only.** Project-scope memories for repos under the qualifying
  `/Users/local/*` roots live in `<project-root>/.claude/memory/` so they sync via the
  project's own remote (see `project-structure.md`).

## Never Commit

- Secrets of any kind — keys, tokens, passwords, connection strings with credentials.
  Reference the Keychain service name or env var instead (see `security.md`).
- Build artifacts and caches — `target/`, `node_modules/`, LaTeX `.aux`/`.bbl`/`.log`,
  `.venv/`. The project `.gitignore` should already exclude these.
- Large generated data or binaries that belong in a backup archive, not version control.

## Forks

- `/Users/local/ghforks/` holds forks that may be modified, committed, and pushed to the
  fork remote — local changes there are expected.

## CHANGELOG

- Projects that ship (CLIs installed via `cargo install`, plugins, libraries) keep a
  `CHANGELOG.md`; `/git-save` maintains it. Note merged PRs there (see this repo's history).

## Anti-Patterns to Avoid

- Committing or pushing without being asked.
- Committing directly to `main` instead of branching first.
- Omitting the `Co-Authored-By` trailer.
- Committing secrets, artifacts, or `node_modules/` / `target/`.
- Hand-running the commit/push/changelog steps when `/git-save` covers them.
