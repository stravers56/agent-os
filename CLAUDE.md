# CLAUDE.md — agent-os

Personal fork of [buildermethods/agent-os](https://github.com/buildermethods/agent-os).
Agent OS manages per-project standards, workflows, and commands for Claude Code and
other AI tools. This repo is the **base installation** — project repos pull from it
via `project-install.sh` / `project-update.sh` (or the `agentos` wrapper in `$scripts`).

## Repository Structure

```
agent-os/
├── config.yml                          # Active profile + inheritance chain (v3.0)
├── commands/agent-os/                  # Shared slash commands installed into projects
│   ├── discover-standards.md
│   ├── index-standards.md
│   ├── inject-standards.md
│   ├── plan-product.md
│   └── shape-spec.md
├── profiles/
│   ├── default/                        # Upstream base profile (empty standards)
│   └── personal/                       # Steven's profile — inherits from default
│       ├── global/tech-stack.md        # High-level stack summary (read by plan-product)
│       ├── standards/                  # Injectable standards (injected by /inject-standards)
│       │   ├── index.yml               # Standard descriptions for /inject-standards matching
│       │   ├── claude-tooling/         # Skills, hooks, MCP servers, SDK/API apps
│       │   ├── database/               # PostgreSQL-default, schema, migrations, security
│       │   ├── documents/              # LaTeX, Word, PowerPoint, Excel conventions
│       │   ├── javascript/             # TypeScript/Obsidian plugin, esbuild, security
│       │   ├── obsidian/               # Calliope vault, CLI, frontmatter, search
│       │   ├── python/                 # uv/venv, project structure
│       │   ├── rust/                   # Edition 2024, deps, error handling, testing
│       │   ├── shell/                  # zsh conventions for /Users/local/scripts/
│       │   ├── git-workflow.md         # Commit discipline, branching, never-commit list
│       │   ├── project-structure.md    # CLAUDE.md/README, project memory, scaffolding
│       │   ├── security.md             # Secrets, input safety, TLS, dep hygiene
│       │   └── testing-and-verification.md  # Verify-before-done, TDD, per-language
│       ├── workflows/                  # Phase instructions installed into agent-os/workflows/
│       │   ├── planning/
│       │   ├── specification/
│       │   └── implementation/
│       └── commands/                   # Profile command overrides (README.md excluded)
│           └── README.md
└── scripts/
    ├── common-functions.sh             # Shared: output helpers, YAML parsing, chain walk,
    │                                   # regenerate_standards_index()
    ├── project-install.sh              # First-time install into a project
    ├── project-update.sh               # Update existing install (prune + backup)
    └── sync-to-profile.sh              # Sync project standards back to a profile
```

## Key Commands

### Install / Update a project

From inside a **project directory** (not here):

```bash
# Using the $scripts wrapper (preferred)
agentos           # prompts: install or update
agentos install   # project-install.sh with default profile (personal)
agentos update --dry-run   # preview changes
agentos update             # apply (prunes orphans, backs up overwritten files)

# Direct scripts
/Users/local/misc/agent-os/scripts/project-install.sh
/Users/local/misc/agent-os/scripts/project-update.sh --dry-run
```

### Sync project standards back to profile

```bash
/Users/local/misc/agent-os/scripts/sync-to-profile.sh --profile personal
```

### Slash commands (installed into projects)

After installing into a project, these are available in Claude Code:

```
/discover-standards   Extract conventions from the project codebase into standards
/inject-standards     Inject relevant standards into context
/shape-spec           Interactive spec creation (run in plan mode)
/plan-product         Create product mission/roadmap/tech-stack docs
/index-standards      Rebuild standards/index.yml
```

## Profile & Inheritance

`config.yml` sets `default_profile: personal`. The `personal` profile
`inherits_from: default` (default profile is currently empty). The install/update
scripts walk the chain base-first (default → personal), later profiles override earlier.

## Adding or Updating a Standard

1. Create or edit `profiles/personal/standards/<category>/conventions.md`
   (subfolder) or `profiles/personal/standards/<name>.md` (root-level for
   cross-cutting concerns).
2. Update `profiles/personal/standards/index.yml` with a one-line description
   (or run `/index-standards` in a project after installing).
3. Reference the standard from `profiles/personal/global/tech-stack.md` if it
   warrants a high-level mention.
4. Commit and push; run `agentos update` in each project to pull the change.

## Git & Remotes

- `origin` → `git@github.com:stravers56/agent-os.git` (personal fork, push target)
- `upstream` → `git@github.com:buildermethods/agent-os.git` (upstream, pull-only)
- Branch: `main`
- No test suite; `bash -n <script>` for syntax checks.

## What Never Goes Here

- Secrets, API keys, or connection strings (source from env / BitWarden Secrets)
- Project-specific notes or memories (those live in the installed project's `.claude/`)
- Absolute user-home paths that won't resolve across machines (`~` / `$HOME` / env vars only)
