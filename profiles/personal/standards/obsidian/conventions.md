# Obsidian Conventions

## Vault

- Vault name: `calliope`
- Location: `/Users/local/obsidian/calliope/`
- Access method: Obsidian CLI (`obsidian vault=calliope ...`)
- Fallback: Claude Code Read/Edit/Write tools (bulk ops or Obsidian not running)

## Note Frontmatter (All Notes)

```yaml
NoteStatus: Final
DateCreated: yyyy-mm-dd
DateModified: yyyy-mm-dd
Title: <title>
tags: []
AIGeneration: Claude
```

## Default Notes

- Location: `$notes` directory
- Additional fields: `RecordType: Note`, `Version: 1.8`

## Search Hierarchy

1. **Semantic search** (complex queries): `obsearch` / `obsearchf`
2. **CLI search** (keyword): `obsidian vault=calliope search query=<text>`
3. **Tags**: `obsidian vault=calliope tag name=<tag> verbose`
4. **Backlinks**: `obsidian vault=calliope backlinks file=<name>`

## Key Directories

Notes, Organizations, People, Broward Health, Author,
Daily Notes, Programming, Purple, Question, Reference,
Research, Topic, Writings, Zotero Notes

## Templates

- Location: `/Users/local/obsidian/calliope/_templates/`
- Prefer CLI: `obsidian vault=calliope create name=<n> template=<t>`
