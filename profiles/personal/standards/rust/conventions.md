# Rust Conventions

## Version & Edition

- Rust 1.92.0, Edition 2024
- Pin `rust-version = "1.92"` in `Cargo.toml` for new projects (lets the resolver pick compatible deps)
- Projects location: `/Users/local/rust/`
- Use the `/rust` skill for version details and edition migration

## When to Use Rust

- Local CLI tools that run frequently and must start fast (sub-100ms cold start matters)
- Data pipelines over large vault scans, fan-out HTTP fetches, or anything where Python's GIL hurts
- Tools you want to `cargo install --path .` and run as a single binary
- Default to Python for one-off scripts; reach for Rust when the tool will stick around

## Project Setup

### Layout

Every project has both a library and a binary, even single-binary tools:

```
project-name/
├── Cargo.toml
├── CLAUDE.md         # Project-specific instructions for Claude Code
├── README.md         # User-facing docs (always present)
├── migrations/       # If the project uses sqlx or rusqlite
├── src/
│   ├── main.rs       # Thin — parse args, dispatch to lib
│   ├── lib.rs        # Module declarations + pub re-exports for integration tests
│   ├── cli.rs        # clap derive structs
│   ├── config.rs
│   ├── error.rs      # thiserror enums
│   └── <feature>/    # Sub-modules grouped by concern (db/, sources/, etc.)
└── tests/
    ├── fixtures/     # Synthetic input data
    ├── snapshots/    # insta or hand-checked outputs
    └── *_e2e.rs      # Integration tests via assert_cmd
```

### Cargo.toml conventions

- `edition = "2024"`, `rust-version = "1.92"`
- Always include `description` for tools you'll install
- When both lib and bin exist, declare them explicitly (`[[bin]]` and `[lib]`) so paths are unambiguous
- Pin major versions only (`"1"`, `"0.12"`); let Cargo resolve minors

## Standard Dependency Stack

The defaults below cover ~90% of CLI tools. Don't deviate without a reason.

### Always

- `clap = { version = "4", features = ["derive"] }` — CLI parsing, derive macros only
- `anyhow = "1"` — error propagation at the binary boundary (in `main.rs` and `cli.rs`)
- `thiserror = "2"` — typed errors inside the library
- `serde = { version = "1", features = ["derive"] }` + `serde_json` / `serde_yaml` as needed
- `tracing = "0.1"` + `tracing-subscriber = { version = "0.3", features = ["env-filter"] }` — logging via `RUST_LOG`

### When async

- `tokio = { version = "1", features = ["rt-multi-thread", "macros"] }` — list explicit features, **don't use `"full"`**
- `reqwest = { version = "0.12", default-features = false, features = ["rustls-tls", "json"] }` — **always `rustls-tls`, never `native-tls`** (avoids OpenSSL on macOS)

### When persisting data

- SQLite: `rusqlite = { version = "0.39", features = ["bundled"] }` — `bundled` so the binary doesn't need a system sqlite
- Postgres: `sqlx = { version = "0.8", default-features = false, features = ["runtime-tokio", "tls-rustls-ring-webpki", "postgres", "chrono", "macros", "migrate"] }`

### When dealing with dates

- `jiff = { version = "0.2", features = ["serde"] }` for new projects (correct time zone handling)
- `chrono = { version = "0.4", features = ["serde"] }` when integrating with code that already uses it

### Common adds

- `walkdir` — directory traversal (Obsidian vault scans, etc.)
- `indicatif` — progress bars for long batch jobs
- `keyring = { version = "3", default-features = false, features = ["apple-native"] }` — macOS Keychain access
- `regex` — prefer `OnceLock` (std) over `lazy_static` for compiled patterns in new code
- `rayon` — data parallelism when CPU-bound and embarrassingly parallel

## Error Handling

Two patterns, pick one per project and stay consistent:

### Pattern A — one app-wide error (smaller tools)

```rust
// src/error.rs
use thiserror::Error;

pub type Result<T> = std::result::Result<T, AppError>;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("config: {0}")]
    Config(String),
    #[error("fetch: {0}")]
    Fetch(#[from] reqwest::Error),
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
}
```

### Pattern B — per-module error enums (larger tools)

```rust
#[derive(Debug, Error)]
pub enum VaultError {
    #[error("failed to read {path}: {source}")]
    Io { path: PathBuf, #[source] source: std::io::Error },
}
```

Then aggregate into `anyhow::Error` at the binary boundary. **Don't use `anyhow` inside library code** — return typed errors so callers can match on them.

## Async

- Use tokio only when you actually need concurrent I/O (HTTP fan-out, multiple files). Sync is faster to write, easier to debug, and starts faster.
- Macros: `#[tokio::main(flavor = "multi_thread")]` for CLI binaries; explicit runtime construction when embedding in tests.
- Don't enable `tokio` feature `"full"` — list features explicitly.
- Async closures (`async || { ... }`) are 2024-edition stable; prefer them over `move ||  async move { ... }` boilerplate.

## CLI Patterns

- clap derive with `#[command(version, about)]` at the top
- Subcommands as an enum with `#[command(subcommand)]`
- For deterministic tests, include a hidden `--today YYYY-MM-DD` style flag (gated with `#[arg(hide = true)]`) so date-sensitive logic is injectable
- Configuration precedence: CLI args > env vars > config file > defaults
- Read secrets from Keychain (via `keyring`) or env vars — never from config files

## Testing

- **Unit tests co-located** in `#[cfg(test)] mod tests { ... }` at the bottom of each source file
- **Integration tests** in `tests/<name>_e2e.rs`, invoking the binary via `assert_cmd` or the library via its public API
- Fixtures in `tests/fixtures/`; snapshots in `tests/snapshots/` (use `insta` for snapshot testing)
- Mock HTTP with `wiremock`; mock filesystem with `tempfile`
- Integration tests rely on `pub` re-exports in `lib.rs` — keep them stable
- Avoid mocks for internal types — use real values, fixtures, or trait objects with simple test implementations

## Performance Profile

For tools where startup or throughput matters, add to `Cargo.toml`:

```toml
[profile.release]
lto = true
codegen-units = 1
opt-level = 3
```

Don't apply this by default — it slows `cargo build --release` noticeably.

## Tooling — Must Be Clean Before Commit

```bash
cargo build                     # Dev build
cargo test                      # All tests
cargo clippy -- -D warnings     # Lint, warnings as errors
cargo fmt --check               # Format check (run cargo fmt to fix)
```

CLAUDE.md in each project should reproduce these commands verbatim.

## Installation

For binaries you'll use locally:

```bash
cargo install --path .
```

Installs to `~/.cargo/bin/` (already on PATH). Re-run after each pull to update.

## Project Memory & Docs

- Every Rust project has both `README.md` (user-facing) and `CLAUDE.md` (Claude-facing)
- CLAUDE.md should document: build/test commands, project structure, key invariants, valid enum values, hidden test flags, and known gaps
- Per-project `type: project` memories live in `<project-root>/.claude/memory/` per the user-scope CLAUDE.md rules

## Anti-Patterns to Avoid

- `reqwest` with `native-tls` or default features (drags in OpenSSL on macOS — always use `rustls-tls`)
- `tokio = { features = ["full"] }` (bloats compile time; list what you actually use)
- `anyhow` inside library code (use `thiserror`; reserve `anyhow` for binaries)
- `unwrap()` / `expect()` outside tests and `main.rs` startup
- `lazy_static!` in new code (use `std::sync::OnceLock` or `LazyLock`)
- Implicit unsafe blocks inside `unsafe fn` (2024 edition requires explicit `unsafe { }` — let clippy enforce)
- Storing the binary in `src/bin/` for single-binary projects (use `src/main.rs` + `[[bin]]`)
- Vendoring deps or committing `target/` (always gitignored)
