# Claude Tooling Conventions

How to build the AI tooling that rides on Claude Code: **skills**, **hooks**,
**MCP servers**, **subagents**, **Agent SDK apps**, and **Claude API apps**. This is
one of the most frequent build activities here, so treat these as first-class
software with the same docs, testing, and git discipline as any other project.

Paths in this file use `~` / `$HOME` and the stable `/Users/local/...` layout so they
resolve on every machine (user IDs and home directories differ across computers).

## Pick the Right Mechanism

| Need | Build a… | Authoritative skill |
|------|----------|---------------------|
| A repeatable, model-driven workflow with explicit trigger conditions | **Skill** | `/skill-creator` |
| A deterministic, automatic action on a Claude Code event (PreToolUse, Stop, etc.) | **Hook** in `settings.json` | `/hookify`, `/update-config` |
| Structured access to an external system (API, DB, app) reusable across sessions | **MCP server** | (see MCP section) |
| A standalone program that drives Claude programmatically | **Agent SDK app** | `/agent-sdk-dev:new-sdk-app` |
| A direct integration calling the Anthropic API | **Claude API app** | `/claude-api` |
| Delegated work needing a fresh context window inside a session | **Subagent** (`Agent` tool) | — |

Rule of thumb: **automatic, every-time behavior → hook** (the harness runs it, not the
model). **Judgment-driven, "use when…" behavior → skill** (the model decides to invoke).
Memory and preferences cannot enforce automatic behavior — only hooks can.

## Skills

Skills live at `~/.claude/skills/<name>/SKILL.md` and sync across machines via the
git-tracked `~/.claude/`. Always build/edit them with the `/skill-creator` skill — it
handles structure, eval, and description tuning.

### Structure

```
~/.claude/skills/<name>/
├── SKILL.md          # Frontmatter + instructions (the only required file)
├── references/       # Detail docs loaded on demand (keep SKILL.md lean)
└── scripts/          # Helper scripts the skill shells out to
```

### Frontmatter

```yaml
---
name: person                       # kebab-case, matches directory name
description: Use when ...           # TRIGGER-oriented; this is how the model decides to load it
model: sonnet                      # sonnet for routine work; omit to inherit; opus for heavy reasoning
effort: medium                     # low | medium | high (optional)
argument-hint: [person name]       # shown in the slash-command UI (optional)
allowed-tools: Read, Write, Edit, Bash, mcp__obsidian__write_note   # least privilege
---
```

- **`description` is the trigger.** Write it as "Use when …" with the concrete nouns and
  verbs that should fire it — not a summary of what the skill does. Triggering accuracy
  is the single highest-leverage thing to get right; tune it with `/skill-creator` evals.
- **`allowed-tools` is least-privilege.** List only the tools the skill actually uses.
  Don't grant `Bash` if `Read`/`Edit` suffice; don't grant write tools to a read-only skill.
- **`model`** — default `sonnet` for routine workflows; reach for `opus` only when the
  skill does substantive reasoning (strategy, analysis, multi-step synthesis).
- Keep `SKILL.md` short; push depth into `references/` files the model reads on demand.

### Conventions

- One skill = one coherent job. If a skill grows multiple unrelated modes, split it.
- Skills shell out to project binaries and CLIs (Obsidian CLI, `zoteroutil`, `latexbuild`,
  Python/Rust tools) rather than reimplementing logic — keep the logic in one place.
- Reference other skills by name (`/editor-manager`, `/zotero`) instead of duplicating
  their procedures.
- `type: project` memory rules don't apply to skills — durable, cross-machine guidance
  belongs in a skill, not in memory (per the global `CLAUDE.md`).

## Hooks

Hooks are deterministic shell commands the harness runs on Claude Code events. Configure
them in `~/.claude/settings.json` (synced) or a project's `.claude/settings.json`. Use
`/hookify` to generate a hook from observed behavior and `/update-config` to edit
`settings.json` safely.

- Use a hook (not memory/preferences) for any "from now on, every time X" requirement —
  the model can't guarantee it, the harness can.
- Hook scripts go in `scripts/` next to the rule; keep them fast (they run inline) and
  exit non-zero only when you intend to block the action.
- Treat hook stdout/stderr as user-facing feedback; make messages actionable.
- Never put secrets in hook commands or `settings.json` — read them from the environment.

## MCP Servers

Servers in regular use are listed in `global/tech-stack.md`. When building or configuring
one:

- **Use the latest version** of each server (per global `CLAUDE.md`).
- Prefer an existing server over shelling out — e.g., `context7` for current library docs,
  `microsoft-docs` for Microsoft/Azure, `firecrawl`/`playwright` for web, `obsidian` for
  the vault, `postgres` for DB queries.
- When writing a custom MCP server, follow the language conventions (Python via `uv`,
  Rust, or TypeScript) and the same secrets rules — credentials from Keychain / env, never
  hard-coded in the server config.
- Document the server's tools and required env vars in its `README.md` and `CLAUDE.md`.

## Subagents (the `Agent` tool)

- Delegate to a subagent when a task is **independent** and benefits from a **fresh context
  window** (broad searches, parallel independent edits, focused analysis).
- Launch independent subagents in a **single message** so they run concurrently.
- Pick the specialized agent type when one fits (`Explore` for read-only fan-out search,
  `Plan` for design, the healthcare/contract/editor agents for their domains); otherwise
  `general-purpose`.
- A subagent's final message is the only thing returned — relay what matters; the user
  never sees the subagent's intermediate output.

## Agent SDK Apps

- Scaffold with `/agent-sdk-dev:new-sdk-app`; verify with the `agent-sdk-verifier-py` /
  `agent-sdk-verifier-ts` agents before considering the app done.
- Python apps run via `uv` (see `python/conventions.md`); TypeScript apps follow
  `javascript/conventions.md`.
- Keep API keys in the environment (exported by `$scripts/apikeys.zsh` from BitWarden
  Secrets) — never in source or committed config.

## Claude API Apps

- Build and migrate with the `/claude-api` skill — it enforces prompt caching and handles
  model-version migrations.
- **Always enable prompt caching** for any non-trivial prompt; it's the default expectation.
- **Use current model IDs.** Default to the latest, most capable model for substantive
  work. Confirm the exact ID with `/claude-api` rather than hard-coding a guessed string —
  model IDs change and stale IDs fail at runtime.
- The Anthropic key is `ANTHROPIC_API_KEY`, exported at shell startup from BitWarden
  Secrets via `$scripts/apikeys.zsh`. Reference the env var; never inline the key.

## Documentation & Git

- Every non-trivial Claude-tooling project (Agent SDK app, MCP server, custom CLI that
  spawns `claude`) has both `README.md` and `CLAUDE.md`, and follows `git-workflow.md`.
- Skills and hooks are versioned implicitly through `~/.claude/` git history — commit them
  there; don't keep one-off edits uncommitted across machines.

## Anti-Patterns to Avoid

- Encoding "always do X" as a memory or preference when it must be a **hook** (memory is
  advisory; only hooks are enforced).
- Writing a skill `description` that summarizes the skill instead of stating its **triggers**.
- Granting a skill broad `allowed-tools` when a narrow set would do.
- Reimplementing logic inside a skill that an existing CLI/skill already provides.
- Hard-coding API keys, model IDs, or absolute user-home paths in skills/hooks/SDK apps —
  use env vars, `/claude-api` for current IDs, and `~`/`$HOME`.
- Building a custom MCP server for something an installed server already covers.
- Skipping the `agent-sdk-verifier-*` check before calling an SDK app done.
