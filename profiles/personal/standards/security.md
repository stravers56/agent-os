# Security & Secrets

Cross-cutting rules for handling secrets, untrusted input, and dependencies in every
project. Language-specific specifics live in the per-language conventions; this is the
shared baseline.

## Secrets Storage

Two stores, picked by what the secret is:

- **BitWarden Secrets** — DB connection strings and rotating API credentials. Exported as
  environment variables at shell startup by `$scripts/apikeys.zsh`. Reference the env var
  (`ANTHROPIC_API_KEY`, `<SLUG>_DATABASE_URL`, …) in code.
- **macOS Keychain** — app-specific tokens and per-tool credentials. Access via the
  `keyring` crate (Rust, `apple-native` feature), `keytar` (JS), `security
  find-generic-password` (shell), or Python `keyring`. Reference by service name.

### Rules

- **Never** embed a secret in source, config, `.env`, a committed key file, or commit
  history. If code must mention one, name the env var or Keychain service — never the value.
- Configuration precedence: CLI args > env vars > config file > defaults. Secrets come from
  env/Keychain only, never from a config file.
- Source `$scripts/apikeys.zsh` (shell) to populate keys; don't re-implement key loading.
- Use `~` / `$HOME` and env-var roots in any path — never hard-code a user-home path that
  won't resolve on another machine.

## Untrusted Input

- **SQL:** parameterized queries only (`$1`, `$2`) — never string concatenation or
  f-strings (see `database/conventions.md`).
- **Shell/child processes:** pass arguments as arrays; use `execFile()` / `spawn()` with
  array args in Node, never a shell-invoking variant with a concatenated string (see
  `javascript/conventions.md`). In zsh, never build a command from untrusted strings.
- **URLs:** encode user-derived components (`encodeURIComponent`, equivalents) before
  building a URL.
- **Embedded scripts (osascript/JXA, SQL, etc.):** serialize data (`JSON.stringify`) and
  inject as a literal — never interpolate raw user strings.
- **Never** evaluate user-supplied strings as code (`eval`, `Function`, etc.).

## Transport

- Require TLS for every network DB or API connection — Postgres `sslmode=require` minimum,
  `verify-full` preferred. Use `rustls-tls` in Rust (`reqwest`), not `native-tls`.

## Dependency Hygiene

- Pin major versions; let the resolver pick compatible minors/patches.
- Address Dependabot alerts promptly — npm/transitive trees especially. Patch transitive
  deps via `overrides` (npm) when the direct dep hasn't shipped a fix.
- Run the language audit before a release (`npm audit`, `cargo audit`, `uv`/`pip-audit`).
- `/git-save` checks Dependabot alerts as part of saving.

## Least Privilege

- App DB connections use a per-project least-privilege role (`<slug>_app`), never the admin
  login or `postgres` superuser (see `database/conventions.md`).
- Skills declare a minimal `allowed-tools` set (see `claude-tooling/conventions.md`).

## Authorized Security Tooling

OSINT and scanning tools (`/osint-tools`, `nist-csf` MCP) are for authorized, defensive,
and research use only — domain/IP/email footprinting against authorized targets, NIST CSF
compliance mapping, contract/security review. Keep usage within that scope.

## Anti-Patterns to Avoid

- Hard-coded secrets, keys, or connection strings anywhere in a repo.
- Committing `.env` or plaintext key files.
- String-concatenated SQL or shell commands from untrusted input.
- `native-tls` / OpenSSL on macOS when `rustls-tls` is available.
- Connecting to a database as an admin/superuser from app code.
- Hard-coded user-home paths that won't resolve across machines.
