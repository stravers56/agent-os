# Tech Stack

High-level summary. Detailed conventions live in `profiles/personal/standards/<category>/conventions.md`.

## Languages

Project directory determines the default language; reach outside it only when the platform demands.

- **Python** (`/Users/local/python/`) — scripting, automation, data processing, single-file tasks. Always run via `uv` in a project-local venv. Multithreading for I/O-bound, multiprocessing for CPU-bound. See [python/conventions.md](../standards/python/conventions.md).
- **Rust** 1.92.0, Edition 2024 (`/Users/local/rust/`) — sticky local CLIs, fast-startup tools, fan-out HTTP, large vault scans, anything where Python's GIL hurts. Install with `cargo install --path .`. See [rust/conventions.md](../standards/rust/conventions.md).
- **TypeScript / JavaScript** (`/Users/local/javascript/`) — primarily **Obsidian plugins** (Electron host, bundled with esbuild, target ES6/CJS). Secondary: small Node CLI utilities. TypeScript by default; plain `.js` only for tiny build scripts. See [javascript/conventions.md](../standards/javascript/conventions.md).
- **zsh** (`/Users/local/scripts/`) — shell glue, backup pipelines, install/sync utilities. The `scripts/` dir is on PATH; many tools are zsh wrappers around Python/Rust internals.
- **LaTeX** — final-form documents and presentations (see Document Authoring below).
- **SQL** — Postgres dialect primarily; SQLite when standing up a server is overkill.

## Database

- **Default:** PostgreSQL for any non-trivial application database.
- **Lightweight alternative:** SQLite for simple, single-user, file-based, or embedded cases.
- **MySQL is retired** — Postgres covers those needs.

### Default Postgres server: `cio-pg-db`

- Host: `cio-pg-db.postgres.database.azure.com` (Azure Flexible Server, Postgres 18.3, region East US 2)
- Admin login: `cioadmin` — credentials in **BitWarden Secrets**, exported at shell startup by `/Users/local/scripts/apikeys.zsh`
- **Per-project convention:** each project gets its own database (slug-named) and a least-privilege `<slug>_app` role; never share databases or use the admin login from app code.
- Connection string exported as `<SLUG>_DATABASE_URL`; `sslmode=require` always.

### Drivers

- Python: `psycopg` (v3) sync, `asyncpg` async — avoid legacy `psycopg2`
- Rust: `sqlx` (compile-time checked, used in `intel_gather` etc.) or `tokio-postgres`
- JavaScript/Node: `postgres` (porsager) or `pg`

See [database/conventions.md](../standards/database/conventions.md) for schema, indexing, migration, security, and backup conventions.

## Document Authoring

Format selected by audience and pipeline, not convenience. Full guidance in [documents/conventions.md](../standards/documents/conventions.md).

- **LaTeX** — default for printed, bound, or PDF-distributed final-form documents (strategic plans, reports, board materials). Document classes: `article`, `book`, `beamer`. **Do not use `memoir`** (stack migrated off).
  - Engine: **XeLaTeX** (required for `fontspec` + BH/MH brand fonts)
  - Bibliography: **biber** + `biblatex` (APA default, Vancouver for some BH clinical docs); `\parencite{}` always, never `\cite`
  - Build via `$scripts/latexbuild` — never hand-run xelatex/biber cycles
  - Templates: `/Users/local/latex-templates/` (generic, BH-branded, MH-branded layered structure)
- **Beamer** — PDF-delivered presentations with BH/MH brand polish (`\usetheme{BH}` / `\usetheme{MH}`)
- **PowerPoint** — live-presentation decks for Microsoft-shop boardrooms. Generated via the `/presentation` skill or `office-files` skill (python-pptx).
- **Word** — short-lived deliverables a stakeholder must edit. Generated via `office-files` (python-docx) for repeatable output; `word-document-server` MCP for in-session edits.
- **Excel** — tabular outputs recipients will sort/filter/pivot. Generated via `office-files` (openpyxl); `excel` MCP for ad-hoc work.
- **Markdown (Obsidian)** — internal notes, drafts later promoted to LaTeX/Word via `/doc-convert` or `/md-to-latex-cite`.

Brand compliance is mandatory for BH/MHS audiences — colors, fonts (Raleway for BH, Montserrat for MHS), logo usage. See `/broward-health-branding` and `/memorial-healthcare-branding` skills.

## Knowledge Management

- **Obsidian vault `calliope`** at `/Users/local/obsidian/calliope/` (`$calliope`)
- **Obsidian CLI** (v1.12.x bundled with installer) is the default access method — fast native binary; requires Obsidian running
- **Zotero** + Better BibTeX for citations; `lib.bib` per LaTeX project; `zoteroutil` for search/add/refresh
- **Semantic search**: `obsearch` / `obsearchf` against the vault before falling back to web search

See [obsidian/conventions.md](../standards/obsidian/conventions.md) for vault structure, frontmatter, search hierarchy, and active plugins (Templater, Dataview, Tasks, Bases, Git).

## AI & Automation

- **Claude Code** as the primary AI development surface; Opus 4.7 (1M context) for substantive work
- **MCP servers** in regular use: `context7` (library docs), `firecrawl` (web crawl/scrape), `playwright` (browser automation), `zapier` (BH Outlook/Calendar), `obsidian`, `word-document-server`, `excel`, `ppt`, `zotero`, `postgres`, `pinecone`, `nist-csf`, `microsoft-docs`, `github`, `slack`, `sequential-thinking`
- **Skills** ride on Claude Code for domain-specific workflows (calendar, email-review, contract-review, editor pipeline, latex, presentation, branding, cio-* operations, etc.)
- **Agent OS** (this repo) for standards management and discovery workflows
- **Subagents** (Explore, Plan, healthcare-financial-analyst, healthcare-strategy-architect, business-doc-editor, contract-reviewer, etc.) for delegated work that benefits from a fresh context window

Building this tooling (skills, hooks, MCP servers, Agent SDK / Claude API apps) is itself a frequent activity — see [claude-tooling/conventions.md](../standards/claude-tooling/conventions.md) for when to use each mechanism and how to structure them.

## Shell & Glue

- **zsh** (`/Users/local/scripts/`, on `PATH`) — backup pipelines, install/sync utilities, and thin wrappers around Python/Rust internals (`obsearch`, `latexbuild`, `pushall`, `zoteroutil`). Shell is glue; promote to Python/Rust the moment real logic appears.
- See [shell/conventions.md](../standards/shell/conventions.md) for safety, temp-file, path-portability, and secrets conventions.

## Engineering Practices (cross-cutting)

Language-agnostic standards that apply to every project:

- **Git** — commit/branch discipline, the `Co-Authored-By` trailer, what never to commit, multi-repo sync via `pushall`/`pullall`. Driven by the `/git-save` skill. See [git-workflow.md](../standards/git-workflow.md).
- **Security & secrets** — BitWarden Secrets (env vars) + macOS Keychain; never embed secrets; parameterized queries and array-arg child processes; TLS everywhere; Dependabot hygiene. See [security.md](../standards/security.md).
- **Testing & verification** — verify before claiming done (evidence before assertions), TDD for non-trivial work, per-language test mechanics. See [testing-and-verification.md](../standards/testing-and-verification.md).
- **Project structure** — every project carries `README.md` + `CLAUDE.md`; in-repo `type: project` memory for qualifying roots; scaffolding and working discipline (clarify-first, brainstorm, scope discipline). See [project-structure.md](../standards/project-structure.md).

## Infrastructure

- **Platform:** macOS (Darwin); zsh shell; Homebrew package manager
- **Local development root:** `/Users/local/` — `python/`, `rust/`, `javascript/`, `scripts/`, `latex/`, `latex-templates/`, `obsidian/`, `misc/`, `temp/`, `datafiles/`, `ghforks/`, `templates/`
- **Temp workspace:** **always** `/Users/local/temp/` (git-tracked, syncs across machines via `pushall`/`pullall`) — never `/tmp/` or `$TMPDIR`
- **Secrets:**
  - **BitWarden Secrets** for DB connection strings and rotating API credentials; exported at shell startup by `apikeys.zsh`
  - **macOS Keychain** for app-specific tokens and per-tool credentials (`keyring` crate in Rust, `keytar` in JS where needed)
  - Never embed secrets in code, config, `.env`, or commit history
- **Backups:** category archive scripts (`*-backup.sh`), `system-mirror.sh`, external drive sync, `bk` for file-level — see `/backup` skill
- **Sync:** `~/.claude/` (skills + global memory) is git-synced across machines; per-project memory under `~/.claude/projects/*/memory/` is local-only. Project-scope memories under qualifying `/Users/local/*` roots live in `<project-root>/.claude/memory/` so they sync via the project's own remote.
