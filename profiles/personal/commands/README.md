# Personal Profile — Command Overrides

This directory is for command definitions specific to the `personal` profile that would
override or supplement the shared `commands/agent-os/*.md` at the repo root
(`discover-standards`, `index-standards`, `inject-standards`, `plan-product`, `shape-spec`).

**Currently only this README** — the shared agent-os commands are used as-is. Add a `.md`
here only when a personal-profile-specific command behavior is needed.

`project-install.sh` and `project-update.sh` install the repo-root `commands/agent-os/`
commands first, then overlay any `profiles/<profile>/commands/**.md` from the inheritance
chain (later profiles override earlier ones by relative path). Subdirectories are preserved
as namespaced commands. `README.md` is skipped — it's documentation, not a command.
