# Implementation Workflow (personal)

How execution should run after a plan/spec is approved. Installed into `agent-os/workflows/`
by `project-install.sh` / `project-update.sh`.

## Execution

- For non-trivial features/bugfixes, **write the failing test first**
  (`/superpowers:test-driven-development`) — rigid workflow, don't adapt away the discipline.
- For plans with independent tasks, consider `/superpowers:subagent-driven-development` or
  dispatching parallel subagents (see `standards/claude-tooling/conventions.md` → Subagents).
- **Scope discipline** — implement what the task specifies; surface adjacent issues rather
  than silently expanding scope.

## Verify Before Done

- Run the project's verification commands and **read the output** before claiming success
  (`standards/testing-and-verification.md`, `/superpowers:verification-before-completion`).
- For behavior changes, drive the real app (`/verify`, `/run`), not just the diff.

## Saving

- Use `/git-save` to commit/push — it runs tests, updates `CLAUDE.md`/`README.md`/CHANGELOG,
  checks Dependabot, and suggests tags (`standards/git-workflow.md`).
- Commit/push only when asked; branch before committing on the default branch.

## Receiving Review

- Apply `/superpowers:receiving-code-review` — verify feedback technically rather than
  agreeing reflexively; push back with evidence when warranted.
