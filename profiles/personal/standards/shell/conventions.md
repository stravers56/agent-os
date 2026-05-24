# Shell (zsh) Conventions

Conventions for the ~125 scripts in `/Users/local/scripts/` (`$scripts`, on `PATH`).
These are the glue layer: backup pipelines, install/sync utilities, and thin zsh wrappers
around Python/Rust internals. Many tools the rest of the stack calls (`obsearch`,
`latexbuild`, `pushall`, `zoteroutil`) are zsh scripts here.

Paths use `~` / `$HOME` and shell env-var roots (`$scripts`, `$python`, `$rust`,
`$calliope`, `$notes`) so scripts run on every machine regardless of user ID.

## When to Use Shell

- Glue and orchestration: chaining existing CLIs, file moves, install/deploy steps.
- Backup and sync pipelines (the `*-backup.sh` / `system-mirror.sh` family).
- Thin wrappers that activate a venv and dispatch to a Python/Rust tool.
- **Reach for Python or Rust** the moment a script grows real logic, data structures, or
  error handling — shell is glue, not an application language.

## Shebang & Interpreter

- `#!/usr/bin/env zsh` for interactive-style scripts and anything using zsh features
  (globbing, arrays, `typeset`). This is the default here.
- `#!/usr/bin/env bash` only when a script must be portable to non-zsh environments.
- Make executable (`chmod +x`) and rely on `PATH` — `$scripts` is on `PATH`, so scripts
  are invoked by bare name (`obsearch`, `pushall`), not by full path.

## Script Header

Document non-trivial scripts at the top, matching the existing `apikeys.zsh` style:

```zsh
#!/usr/bin/env zsh
#
# Script: <name>.zsh
# Description: <one line>
# Usage: <how to invoke, key flags>
#
```

## Safety

- Quote every expansion: `"$var"`, `"$@"`, `"${arr[@]}"`. Unquoted paths break on spaces.
- For pipelines and non-interactive scripts, fail loudly:
  ```zsh
  set -e          # exit on error
  set -u          # error on unset variables
  set -o pipefail # a failing stage fails the pipe
  ```
  (Relax deliberately where a command is expected to fail and you handle it.)
- Prefer arrays for argument lists; never build a command by string-concatenating
  untrusted input.
- Check preconditions before destructive steps; guard `rm -rf` with a verified variable,
  never an unguarded interpolation.

## Temp Files

Always use the project temp workspace, **never** `/tmp` or `$TMPDIR` (per global `CLAUDE.md`
— `/Users/local/temp/` is git-tracked and survives reboots):

```zsh
TEMP_DIR=$(mktemp -d -p /Users/local/temp)
trap 'rm -rf "$TEMP_DIR"' EXIT
```

Always pair `mktemp` with a `trap ... EXIT` cleanup.

## Paths & Portability

- Reference roots through env vars defined in the shell profile: `$scripts`, `$python`,
  `$rust`, `$calliope`, `$notes`, `$icloudpath`, `$bh`, `$mh`.
- Use `$HOME` (not a hard-coded `/Users/<name>`) for anything under the home directory —
  user accounts differ across machines.
- The `/Users/local/...` layout is stable across machines and acceptable when no env-var
  alias exists.

## Secrets

- Source `$scripts/apikeys.zsh` to pull API keys from BitWarden Secrets / macOS Keychain
  at the top of any script that needs them:
  ```zsh
  [[ -f "$scripts/apikeys.zsh" ]] && source "$scripts/apikeys.zsh"
  ```
- Read individual secrets from the Keychain with `security find-generic-password` (see
  `apikeys.zsh` / `keychain-setup.zsh` for the service-name convention).
- **Never** hard-code keys, tokens, or connection strings; never echo a secret; never
  commit a plaintext key file.

## Wrapping Python / Rust

The common pattern — activate the project venv and dispatch (as in `obsearch`):

```zsh
#!/usr/bin/env zsh
cd "$python/<project>"
source "$python/<project>/venv/bin/activate"
python3 "./<entry>.py" "$@"
```

For Rust tools, prefer `cargo install --path .` so the binary lands on `PATH` directly and
no wrapper is needed.

## Parallelism

For fan-out work (the `pushall`/`pullall` multi-repo pattern), background jobs writing to a
`mktemp -d` results dir, then `wait`, is the established approach. Keep a job counter for
unique temp filenames and clean up with the `EXIT` trap.

## Installation & PATH

- New utilities go in `$scripts` (`/Users/local/scripts/`) so they're immediately on `PATH`.
- Project-local deploy scripts (e.g., `<plugin>install.sh`, `sync-templates.sh`) live in
  the project repo, not in `$scripts`.

## Backups & Sync

- Category archives follow the `<category>-backup.sh` naming (`obsidian-backup.sh`,
  `python-backup.sh`, …); `system-mirror.sh` mirrors the system. Use the `/backup` skill to
  run, verify, or troubleshoot rather than invoking by hand when the skill covers it.
- `pushall` / `pullall` sync the multi-repo working set (including `~/.claude/` and
  `/Users/local/temp/`) across machines.

## Anti-Patterns to Avoid

- Unquoted variable expansions (`$file` → `"$file"`).
- `/tmp` or `$TMPDIR` for scratch — always `/Users/local/temp/`.
- Hard-coded `/Users/<name>/...` home paths — use `$HOME` or an env-var root.
- Growing real application logic in zsh — promote to Python or Rust.
- Building commands by concatenating untrusted strings.
- Hard-coded secrets or plaintext key files.
- `mktemp` without a matching `trap` cleanup.
- Duplicating logic that an existing `$scripts` tool or skill already provides.
