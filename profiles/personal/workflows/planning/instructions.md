# Planning Workflow (personal)

Overlay on the default `/plan-product` and `/shape-spec` commands. Captures how planning
should run in this profile.

`project-install.sh` and `project-update.sh` install `profiles/<profile>/workflows/` into a
project's `agent-os/workflows/`, walking the profile inheritance chain.

## Before Planning

- **Clarify first.** Ask concise, numbered questions about scope, output format, affected
  files/systems, and whether to commit/push before producing a plan. Proceed without asking
  only on unambiguous direct commands. (See `standards/project-structure.md` → Working
  Discipline.)
- **Brainstorm creative work** with `/superpowers:brainstorming` before settling a design.

## Gathering Context (priority order)

1. **Institutional knowledge** — `obsearch` / `obsearchf` against the calliope vault, then
   the project's own `research/` directory (see `standards/obsidian/conventions.md`).
2. **Library/API docs** — `context7` MCP (any library/framework/SDK), `microsoft-docs` for
   Microsoft/Azure. Prefer these over web search for current docs.
3. **Web** — only after local sources are exhausted.

## Surfacing Standards

Read `standards/index.yml` and pull the standards relevant to what's being built — always
include the cross-cutting ones (`git-workflow`, `security`, `testing-and-verification`,
`project-structure`) plus the language/category standards that apply.

## Output

Use `/shape-spec` (in plan mode) for spec-worthy work; `/superpowers:writing-plans` for a
multi-step plan that doesn't need a full spec folder.
