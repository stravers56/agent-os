# Obsidian Conventions

## Vault

- Vault name: `calliope`
- Location: `/Users/local/obsidian/calliope/` (env var `$calliope`)
- Notes root: `$notes` (Notes directory under the vault)
- Access method: Obsidian CLI (`obsidian vault=calliope ...`) — requires Obsidian running
- Fallback: Claude Code Read/Edit/Write tools (bulk ops, complex replacements, or Obsidian not running)
- CLI binary: bundled with Obsidian Installer as of v1.12.7 (fast native CLI, replaces old Electron-binary method)

## Frontmatter

### Required on every note

```yaml
NoteStatus: Final              # Draft | Final
DateCreated: yyyy-mm-dd
DateModified: yyyy-mm-dd       # update on every edit
Title: <title>
tags: []
AIGeneration: Claude           # add when Claude touches the note
```

### Default notes (under `$notes`)

```yaml
RecordType: Note
Version: 1.8
```

### Common optional fields (use when applicable)

- `RecordType`: `Note` | `Topic` | `Organization` | `Person` | `Reference` | `Project` | `Meeting` | `Question`
- `aliases`: alternative names for wiki-link resolution
- `References`: related citations and sources
- `RefTags`: cross-linking reference tags
- `CommonBook`: shared knowledge categorization
- `KnowledgeBase: true`
- `TemplateVersion`: tracks template version used to create the note

### Project notes (template v2.0)

- `DateStatusUpdated`: last date `ProjectStatus` or `PercentComplete` changed
- `BlockedBy`: wikilink list, e.g. `["[[Vendor X]]", "[[Budget Approval]]"]`
- `DelayReason`: free-text explanation of delays

## Tags

- **Style**: PascalCase / camelCase, no hyphens. `#Strategy`, `#ActionStrategy` — never `#action-strategy`.
- Tags are hierarchical; use the existing taxonomy before inventing new tags.
- Every `Topic/<X>.md` note should have a matching `#X` tag in active use (orphans flagged by `obsidian-maintenance`).

## Key Directories

`Notes`, `Daily Notes`, `Research`, `Reference`, `Readwise`, `Programming`,
`Broward Health`, `USA Health`, `Memorial Healthcare`, `Organizations`, `People`,
`Author`, `Topic`, `Question`, `Writings`, `Zotero Notes`, `AI`, `Purple`

## Templates

- Location: `/Users/local/obsidian/calliope/_templates/`
- Templater syntax (`<% ... %>`); helper scripts in `_templaterscripts/`
- Prefer CLI: `obsidian vault=calliope create name=<n> template=<t>`
- Common templates: `Note Template`, `Topic`, `Organization`, `Person`, `Reference`, `Project`, `Meeting`

## Search Hierarchy

| Order | Tool | When |
|-------|------|------|
| 1 | `obsearch <query>` / `obsearchf <query>` | Conceptual queries, knowledge discovery, multi-note synthesis |
| 2 | `obsidian vault=calliope search:context query=<text>` | Keyword search with matching line context |
| 3 | `obsidian vault=calliope search query=<text>` | Keyword search (file paths only) |
| 4 | `obsidian vault=calliope tag name=<tag> verbose` | Tag-based navigation |
| 5 | `obsidian vault=calliope backlinks file=<name>` | Relationship discovery |

`obsearch` returns matching chunks; `obsearchf` returns full text from identified sections.

## Dataview and Bases

- Dataview queries (` ```dataview ` blocks and `.base` files): run via `dvquery` or the `/dataview-query` skill.
- Base operations via CLI: `bases`, `base:query`, `base:views`, `base:create`.

## CLI Behavior Notes (v1.12.x)

- **Silent by default** — do NOT pass a `silent` parameter. Use `open` to open the target after the operation.
- **`active`** targets the active file (replaces the old `all` parameter).
- **`search:context`** is a separate command from `search` (formerly `search matches=...`).
- New commands available: `daily:path`, `rename`, `base:query`, `base:create`, `bases`.
- Terminal autocompletion works when using `id=` parameters (v1.12.5+).
- Append `--copy` to any command to copy output to clipboard.

Source of truth for CLI changes: `$notes/Obsidian-CLI-Notes.md`. Use the `/obsidian-cli-update` skill to sync this document and CLAUDE.md files after CLI updates.

## Markdown Gotchas

### Wiki links inside table cells

Escape the pipe inside `[[...|...]]` when used in a Markdown table, otherwise it is parsed as a column delimiter and silently mangles the table:

```markdown
| Project | Owner |
|---------|-------|
| [[Projects/EHR Migration\|EHR Migration]] | Cathy |
```

Audit with: `rg -n '\[\[[^\]]*\|[^\]]*\]\]' /Users/local/obsidian/calliope/ --glob "*.md"` — any match without a preceding `\` inside a table row is a bug.

## Editing Discipline

- Commit any uncommitted changes to a note **before** modifying it (the vault is a git repo — preserves a backup).
- Update `DateModified` on every edit.
- Add `AIGeneration: Claude` when Claude modifies content.
- Prefer `obsidian vault=calliope property:set name=<prop> value=<val> file=<name>` for single-field frontmatter changes.

## Plugins in Active Use

- **Templater** — dynamic templates with custom JS helpers
- **Dataview** — database-style queries with table/list views
- **Tasks** — query-based task management, central `Tasks.md` hub
- **Bases** — native Obsidian database views (`.base` files)
- **Git** — version control for backup and sync

## Related Skills

- `/obsidian-search` — semantic search with structured output
- `/obsidian-maintenance` — vault hygiene (tags, frontmatter, orphans, broken links)
- `/obsidian-project-report` — project reports and dashboards
- `/obsidian-cli-update` — sync this file and CLAUDE.md after CLI updates
- `/project-validate` — project-note data quality checks
- `/dataview-query` — execute Dataview queries
- `/meeting-note` — create meeting notes with proper templates and folder placement
