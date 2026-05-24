# JavaScript / TypeScript Conventions

## Environment

- Projects location: `/Users/local/javascript/`
- Node.js LTS (20.x or newer) for build tooling and CLI scripts
- Primary use case: **Obsidian plugins** (desktop-only, runs in Electron host); secondary: small Node CLI utilities
- `_archive/` holds retired plugins as `.zip` snapshots — historical reference only

## When to Use JavaScript / TypeScript

- Obsidian plugin development (the platform requires it)
- Browser-facing or Electron-hosted code
- Existing JS/TS codebases where the language is already established
- **Default to Python for one-off scripts and Rust for sticky local CLIs** — only reach for Node when the platform demands JS or there is a strong ecosystem reason (esbuild, a specific npm-only library, etc.)

## Language Choice: TypeScript by Default

- New projects use TypeScript, not plain JavaScript
- Plain `.js` only for tiny build scripts (`esbuild.config.mjs`, `version-bump.mjs`) and zsh-shelled-out helpers
- Target `ES6` / `es2016` for Obsidian plugins (matches Electron host); `ES2022` or newer for Node-only code
- Modules: `ESNext` source modules; `cjs` output for Obsidian (plugin host loads CommonJS), `esm` for modern Node

## Project Setup (Obsidian Plugin)

### Layout

```
plugin-name/
├── CLAUDE.md              # Project-specific instructions for Claude Code
├── README.md              # User-facing docs
├── manifest.json          # Obsidian plugin manifest (id, version, minAppVersion, isDesktopOnly)
├── package.json           # npm dependencies + scripts
├── package-lock.json      # Always committed
├── tsconfig.json          # TypeScript compiler config
├── esbuild.config.mjs     # Bundler config (esbuild, not webpack/rollup)
├── .eslintrc.yml          # ESLint config
├── .gitignore             # Standard Node ignores; never commit node_modules/
├── main.ts                # Plugin source (single-file plugins are fine)
├── main.js                # Bundled output (committed for Obsidian distribution)
├── styles.css             # Plugin CSS
├── versions.json          # Obsidian minAppVersion → plugin version map
├── version-bump.mjs       # Bump script wired to npm version
├── <project>install.sh    # Build + deploy script (zsh)
└── test_obsidian_vault/   # Local test vault (gitignored)
```

### package.json conventions

- Always `"main": "main.js"` for Obsidian plugins
- Standard scripts:
  - `"dev": "node esbuild.config.mjs"` — watch mode
  - `"build": "tsc -noEmit -skipLibCheck && node esbuild.config.mjs production"` — type-check then bundle
  - `"version": "node version-bump.mjs && git add manifest.json versions.json"` — keep `manifest.json` / `versions.json` in lockstep with `package.json`
- Pin major versions in dependencies; let npm resolve minor/patch
- Use `"overrides"` to force transitive-dep upgrades when Dependabot flags a vulnerability you can't fix at the direct-dep level (e.g., `minimatch`, `brace-expansion`, `flatted`)

### tsconfig.json conventions

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "inlineSourceMap": true,
    "inlineSources": true,
    "module": "ESNext",
    "target": "ES6",
    "allowJs": true,
    "noImplicitAny": true,
    "moduleResolution": "node",
    "importHelpers": true,
    "isolatedModules": true,
    "lib": ["DOM", "ES5", "ES6", "ES7"]
  },
  "include": ["**/*.ts"]
}
```

- `noImplicitAny: true` is mandatory — opt-in `any` only with explicit annotation
- `isolatedModules: true` keeps each file independently compilable (required by esbuild)
- `importHelpers: true` pulls TS helpers from `tslib` instead of inlining them in every output
- Use `tsc -noEmit` purely for type-checking; let esbuild emit the bundle

## Standard Dependency Stack

### Always (Obsidian plugin)

- `obsidian` — types and APIs, pin to `"latest"` in devDependencies (Obsidian resolves it at runtime)
- `typescript`, `tslib` — language + helper runtime
- `esbuild` — bundler (not webpack, not rollup, not parcel — esbuild is fast and the Obsidian template standard)
- `builtin-modules` — used by `esbuild.config.mjs` to externalize Node built-ins
- `eslint` + `@typescript-eslint/parser` + `@typescript-eslint/eslint-plugin` — lint
- `@types/node` — Node type declarations

### Build externals (esbuild)

Externalize at bundle time so the Obsidian host provides them:

- `obsidian`, `electron`
- All `@codemirror/*` modules
- Everything in `builtin-modules` (Node built-ins)

Format: `cjs`. Target: `es2016`. Source maps: `inline` in dev, off in production.

## ESLint

Minimal config — opinionated lint rules add friction in single-author plugins:

```yaml
env:
  browser: true
  es2021: true
extends:
  - eslint:recommended
  - plugin:@typescript-eslint/recommended
parser: '@typescript-eslint/parser'
parserOptions:
  ecmaVersion: latest
  sourceType: module
plugins:
  - '@typescript-eslint'
rules: {}
```

## Child Process Patterns

External commands are common (spawning `claude`, `pandoc`, `pdflatex`, `osascript`, `open`). Follow these rules without exception:

- **Use `execFile()` for one-shot commands**, never the shell-invoking variant — the shell variant is vulnerable to argument injection
- **Use `spawn()` for long-running / streaming output** (NDJSON consumers, watch processes)
- Pass arguments as an **array**, never as a concatenated string
- Always handle `error`, `stderr`, and non-zero exit codes — surface them to the user via `new Notice()` in Obsidian plugins, log to `console.error()` everywhere else

### Streaming NDJSON (e.g., Claude CLI integration)

- `spawn()` with `--output-format stream-json`
- Call `child.stdin.end()` immediately after spawn if no further input — otherwise the CLI hangs waiting on stdin
- Parse stdout line-by-line; each line is a JSON event
- Track session state on the service object (e.g., `sessionId`); pass `--resume <id>` on subsequent calls
- Always handle partial lines at chunk boundaries (buffer the tail)

## Filesystem Patterns

- Use Node's `fs` directly: `fs.copyFileSync()`, `fs.unlinkSync()`, `fs.readdirSync({ withFileTypes: true })`, `fs.existsSync()`
- **Never shell out for file ops** (no spawning `cp`, `rm`, `mv` — use `fs` APIs)
- Resolve `~` and `$HOME` at runtime via `os.homedir()` so configs sync cleanly across machines
- Read frontmatter with simple regex or yaml parsing — pull in `gray-matter` only if needed across multiple files

## Security Conventions

- **No shell-invoking child_process APIs** — always `execFile()` or `spawn()` with array args
- **No shell-string concatenation** for file or URL operations
- **Never evaluate user-supplied strings as code** — no dynamic code evaluation, no Function constructor on tainted input; parse JSON with `JSON.parse()`
- Encode user-derived URL components with `encodeURIComponent()` before building URLs
- For embedded scripts (osascript / JXA), serialize all data with `JSON.stringify()` and inject as a literal — never interpolate raw strings
- Wrap paths containing spaces in single quotes when copying to clipboard for shell use
- Keep credentials in the macOS Keychain (`keytar` if needed) or env vars; never check secrets into `package.json`, `.env`, or source

## Cross-Platform & Sync Patterns

- Resolve user-config paths at runtime, not at install time — the same `package.json` runs on multiple machines via vault sync
- For Obsidian plugins, prefer settings stored via `loadData()` / `saveData()` (per-vault) over hard-coded paths
- For macOS-specific integrations (Apple Contacts, Warp, Ghostty), gate by capability — but `isDesktopOnly: true` in `manifest.json` is the simpler stance for plugins that need Node APIs

## macOS Integration via JXA

When automating macOS apps (Contacts, Calendar, Mail), prefer JXA (JavaScript for Automation) over AppleScript — same Apple Events bus, but JS syntax and `JSON.stringify` make data injection safe:

```js
execFile('osascript', ['-l', 'JavaScript', '-e', script], (error, stdout, stderr) => { ... });
```

- Build the script as a template literal with the data embedded as `JSON.stringify(data)`
- Swallow non-critical errors (e.g., photo read failures) so the primary operation still succeeds
- Note the AppleScript / JXA limitations: cannot target a specific account on contact creation; new contacts land in the default account

## Build & Deploy

- `npm run build` — type-check + production bundle
- `npm run dev` — watch mode for development
- Per-project deploy script (zsh) handles copying `main.js`, `manifest.json`, `styles.css` to vault plugin directories:

```bash
./<plugin>install.sh           # deploy to test vault
./<plugin>install.sh --prod    # deploy to calliope vault
./<plugin>install.sh --prod --test   # both
```

- Bump version in `package.json`, then `npm version <patch|minor|major>` to update `manifest.json` and `versions.json` via the version script

## Dependency Hygiene

- Review and address Dependabot alerts promptly — npm transitive trees are deep and CVE-laden
- Patch transitive deps via `package.json` `"overrides"` when the direct dep hasn't released a fix yet
- Run `npm audit` before every release; commit the `package-lock.json` so reproducible builds catch regressions
- Don't pin obsidian-template-managed devDeps to exact versions — use `^` to track upstream fixes

## Testing

Plugin testing is mostly manual (Obsidian's API surface is hard to mock):

- Keep a `test_obsidian_vault/` (gitignored) with representative notes, plugin configs, and edge-case files
- Deploy to the test vault via the `--test` flag; reload Obsidian (`Cmd-R` in dev) and exercise commands
- For pure-logic modules, drop in `vitest` and run `npm test` against the source — but don't introduce a test framework just to write one test

## Project Memory & Docs

- Every plugin has both `README.md` (user-facing) and `CLAUDE.md` (Claude-facing)
- `CLAUDE.md` documents: build/deploy commands, project structure, settings schema, command/menu surface, security conventions specific to the plugin, known quirks
- Per-project `type: project` memories live in `<project-root>/.claude/memory/` per the user-scope CLAUDE.md rules

## Anti-Patterns to Avoid

- Shell-invoking child_process APIs (injection risk — use `execFile()` or `spawn()` with array args)
- Shell-string concatenation for paths, URLs, or osascript snippets
- Bundling with webpack or rollup for new Obsidian plugins (esbuild is the standard)
- Plain JavaScript when TypeScript adds no friction
- `any` without an explicit annotation; disabling `noImplicitAny`
- Hard-coded absolute paths in source — resolve `~` / `$HOME` at runtime
- Committing `node_modules/`, `.env`, or build caches
- Spawning a CLI that reads stdin without calling `stdin.end()` (causes hangs)
- Adding test frameworks, lint plugins, or build tooling beyond what the project actually exercises
