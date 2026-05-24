# Specification Workflow (personal)

Overlay on the default `/shape-spec` command. Installed into `agent-os/workflows/` by
`project-install.sh` / `project-update.sh`.

## Principles

- **Keep it lightweight** — shape enough to start; refine as you build. Don't over-document.
- **Task 1 is always "Save spec documentation"** (per `/shape-spec`), so the shaping work is
  preserved before implementation.
- **Use `AskUserQuestion`** for every clarification — offer options the user can confirm,
  adjust, or correct.

## Spec Folder

`/shape-spec` writes `agent-os/specs/{YYYY-MM-DD-HHMM-feature-slug}/` containing `plan.md`,
`shape.md`, `standards.md`, `references.md`, and `visuals/`. The `standards.md` file should
embed the full content of each applicable standard, including the cross-cutting ones.

## Definition of Done (carry into the spec)

- Verification command(s) identified up front (see `standards/testing-and-verification.md`).
- `CLAUDE.md` / `README.md` updates listed as explicit tasks.
- Secrets and config handling specified per `standards/security.md`.
