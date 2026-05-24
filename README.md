<img width="1200" height="675" alt="Agent OS" src="https://github.com/user-attachments/assets/97ad4491-d199-4b9b-9482-ae710291dfb4" />

## Agents that build the way you would

[Agent OS](https://buildermethods.com/agent-os) helps you shape better specs, keeps agents aligned in a lightweight system that fits how you already build.

Works alongside Claude Code, Cursor, Antigravity, and other AI tools. Any language, any framework.

**Core capabilities:**

- **Discover Standards** — Extract patterns and conventions from your codebase into documented standards
- **Deploy Standards** — Intelligently inject relevant standards based on what you're building
- **Shape Spec** — Create better plans that lead to better builds
- **Index Standards** — Keep your standards organized and discoverable

---

### Installing & updating a project

From inside a project directory:

```bash
# First-time install — copies standards, workflows, and commands from the active profile
/path/to/agent-os/scripts/project-install.sh

# Update an existing install to match the current profile
/path/to/agent-os/scripts/project-update.sh --dry-run   # preview every change first
/path/to/agent-os/scripts/project-update.sh             # apply
```

Both scripts walk the profile inheritance chain (e.g. `personal` → `default`) and install:

- `standards/**` → `agent-os/standards/` (with a regenerated `index.yml`)
- `workflows/**` → `agent-os/workflows/`
- repo-root `commands/agent-os/*` plus any `profiles/<profile>/commands/**` → `.claude/commands/agent-os/`

**`project-install.sh`** only adds/overwrites (it prompts before replacing existing
standards). **`project-update.sh`** additionally **prunes** files that no longer exist in the
profile and **backs up** anything it overwrites or removes to `agent-os/.backups/<timestamp>/`,
so it's the safe way to pull breaking changes into an older install. Always run it with
`--dry-run` first. Add `agent-os/.backups/` to the project's `.gitignore`.

Useful flags: `--profile <name>`, `--commands-only` (install), `--no-prune` / `--no-backup`
(update).

---

### Documentation & Installation

Docs, installation, usage, & best practices 👉 [It's all here](https://buildermethods.com/agent-os)

---

### Follow updates & releases

Read the [changelog](CHANGELOG.md)

[Subscribe to be notified of major new releases of Agent OS](https://buildermethods.com/agent-os)

---

### Created by Brian Casel @ Builder Methods

Created by Brian Casel, the creator of [Builder Methods](https://buildermethods.com), where Brian helps professional software developers and teams build with AI.

Get Brian's free resources on building with AI:
- [Builder Briefing newsletter](https://buildermethods.com)
- [YouTube](https://youtube.com/@briancasel)

Join [Builder Methods Pro](https://buildermethods.com/pro) for official support and connect with our community of AI-first builders:

