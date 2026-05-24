# Document Production Conventions

## Format Selection

Pick the format from the audience and the production pipeline, not from convenience:

- **LaTeX** — anything that gets printed, bound, distributed as PDF, or needs a real bibliography. Strategic plans, books, formal reports, board-distributed deliverables. Default for any document where typography and reproducibility matter.
- **PowerPoint** — leadership presentations, decks meant for live presentation in a Microsoft-shop boardroom. Generated via the `presentation` skill or `office-files` skill (Python python-pptx), not hand-built in the app.
- **Word** — when a stakeholder must edit and the document is short-lived. Generated via `office-files` (Python python-docx) for repeatable output; the `word-document-server` MCP is the alternative for single-shot edits inside an active conversation.
- **Beamer** — when a presentation needs the same brand polish as the matching LaTeX report (BH/MHS-themed) and will be delivered as a PDF, not a `.pptx` round-trip.
- **Excel** — anything tabular that recipients will sort, filter, pivot, or extend. Generated via `office-files` (Python openpyxl) for repeatable models; the `excel` MCP for ad-hoc work in-session.
- **Markdown (Obsidian)** — internal notes, knowledge base, drafts that will later be promoted to LaTeX or Word via the `doc-convert` or `md-to-latex-cite` skills.

Default to LaTeX whenever the choice is between LaTeX and Word for a final-form document.

## LaTeX

Projects location: `/Users/local/latex/`
Templates location: `/Users/local/latex-templates/`
Use the `/latex` skill for writing/editing guidance and the `/latexbuild` skill for build/scaffolding.

### Document Class Selection

- **`article`** — short documents (memos, single-section reports, one-pagers). Use `Document-Template` or `BH-Document-Template` / `MH-Document-Template`.
- **`book`** — multi-chapter strategic plans, IT roadmaps, formal reports, books. Use `Report-Template` or `Book-Template`. This is the default for anything multi-section.
- **`beamer`** — presentations meant for PDF delivery (`aspectratio=169` for modern projectors). Use BH/MH beamer themes (`\usetheme{MH}` / `\usetheme{BH}`).

**Do not use `memoir`.** The stack migrated off it. Old gitignore patterns still mention `*.mw` — that's history, not current practice.

### Compiler & Build

- Engine: **XeLaTeX** (required for `fontspec` and the BH/MH brand fonts)
- Bibliography: **biber** with `biblatex`
- Build via the `latexbuild` script — never hand-run `xelatex`/`biber` cycles:

```bash
$scripts/latexbuild              # Full build (run xelatex → biber → xelatex × 2)
$scripts/latexbuild --quick      # Quick rebuild — no bibliography changes
$scripts/latexbuild --lib        # Full rebuild after lib.bib changes
$scripts/latexbuild --clean      # Remove auxiliary files
```

The script auto-detects the main `.tex` file by scanning for `\documentclass`. If multiple `.tex` files at the root have `\documentclass`, pass `--main <file>`.

### Project Layout

```
Project-Name/
├── CLAUDE.md                          # Project-specific instructions for Claude Code
├── README.md                          # Human-facing overview
├── ProjectName.tex                    # Master document (matches dir name)
├── lib.bib                            # Bibliography (managed via Zotero + zoteroutil)
├── chapters/                          # \include{}-d chapter files for book class
├── img/                               # Figures, logos
├── research/                          # Source notes, drafts, supporting docs
├── data/                              # CSVs, tables generated from analysis
├── comments/                          # Reviewer markup (when applicable)
├── cspell.json                        # Project-specific spelling dictionary
└── .gitignore                         # From Common-Elements/gitignore_template
```

### Templates

The `latex-templates` repo has a layered structure:

- **`Common-Elements/`** — shared baseline: `CLAUDE.md`, `lib.bib` skeleton, `gitignore_template`, `claude_settings.local.json`. `sync-templates.sh` pushes these into every `*Template/` directory; run it after editing any common file.
- **Generic templates** — `Document-Template` (article), `Report-Template` (book), `Book-Template` (book with crop marks, royal-octavo trim). Use the `trav-*` color palette.
- **Branded templates** — `BH-Document-Template`, `BH-Report-Template`, `MH-Document-Template`, `MH-Report-Template`, `MH-Presentation-Template`. Use the official brand fonts and colors; consult the `broward-health-branding` and `memorial-healthcare-branding` skills before changing anything visual.

When scaffolding a new project, prefer the most specific template (branded > generic) and copy the entire directory rather than cherry-picking files — the `.claude/`, `.gitignore`, and `CLAUDE.md` are part of the contract.

### Standard Preamble

Every LaTeX document loads the same core packages. Don't deviate without a reason:

```latex
\usepackage[style=apa,backend=biber]{biblatex}
\usepackage{adjustbox, booktabs, comment, enumitem, fancybox, fancyhdr, float}
\usepackage{fontspec, fontawesome5, geometry, graphicx}
\usepackage{layout, lipsum, longtable, makeidx, nameref, pdfpages}
\usepackage{ragged2e, tablefootnote, titlesec, todonotes, url, xcolor, xspace}
\usepackage{hyperref}   % Must be loaded LAST
```

Branded additions:
- BH: `\usepackage{raleway}` (sets Raleway as the sans-serif default)
- MHS: `\usepackage{montserrat}` (sets Montserrat as the sans-serif default)
- Mono font (everywhere): `\setmonofont{SourceCodePro}[Extension=.otf, ...]`

### Page & Typography Defaults

- Margins: `left=1.0in, right=1.0in, top=1.0in, bottom=1.3in` (book) / `1.0in` all around (article)
- `\raggedbottom` — variable page bottom over forced vertical justification
- `\hyphenpenalty=10000` — no hyphenation (we'd rather have a longer line than a hyphenated word)
- `\hbadness=10000` — suppress underfull hbox warnings (they're noise for our content)
- `\renewcommand{\familydefault}{\sfdefault}` — sans serif body, paired with Raleway/Montserrat
- Section numbering: `\setcounter{secnumdepth}{0}` for articles (suppress numbering), `{2}` or `{3}` for book-class strategic plans
- Line spacing: `\onehalfspacing` (from `setspace`) for book-class long-form
- List labels:
  ```latex
  \setlist[enumerate,2]{label=\Alph*)}
  \setlist[enumerate,3]{label=\arabic*)}
  \setlist[enumerate,4]{label=\alph*)}
  ```
- `\graphicspath{{./img/}}` — figures live in `img/`

### Colors

Three palettes, one per audience. Always reference colors by named token, never raw RGB/HTML in body text.

- **Broward Health** (HTML hex, brand-official):
  ```latex
  \definecolor{BHDarkBlue}{HTML}{02225A}     % Primary
  \definecolor{BHSkyBlue}{HTML}{116DD3}      % Links, CTAs
  \definecolor{BHOceanBlue}{HTML}{1DAFE5}    % Accents
  \definecolor{BHSeaFoamBlue}{HTML}{9CE4EE}  % Backgrounds
  % ... plus BHPaleRed, BHYellow, BHPurple, BHAqua, BHTeal, BHSand, BHStone, BHSeaSalt
  ```
  Full palette and usage rules in the `broward-health-branding` skill (sourced from `BHC_BrandStyleGuide.pdf v1.3`).

- **Memorial Healthcare System** (RGB, brand-official):
  ```latex
  \definecolor{mhs-blue}{RGB}{26,71,150}
  \definecolor{mhs-teal}{RGB}{22,166,176}
  % ... plus mhs-teal-dark, mhs-cyan, mhs-red, mhs-orange, mhs-purple, mhs-bright-cyan
  ```
  Full palette in the `memorial-healthcare-branding` skill.

- **Generic / personal** — `trav-*` prefix (`trav-dark-blue`, `trav-midnight-blue`, etc.) for unbranded documents.

`hyperref` should always be colorized with the audience-appropriate palette:

```latex
\hypersetup{colorlinks=true, citecolor={...}, anchorcolor={...}, linkcolor={...}, urlcolor={...}}
```

### Citations & Bibliography

- Citation command: **`\parencite{key}`** (always — never `\cite`)
- Style: **APA** by default (`style=apa`); **Vancouver** for some Broward Health clinical / strategic documents — check the project's `\usepackage[style=...]{biblatex}` line, don't assume
- Bibliography file: `lib.bib` at project root, managed via Zotero + Better BibTeX
- Citation keys follow BBT format: `authorTitleWordsYear` (e.g., `hatchOrganizationTheoryModern2013`)

#### Citation Workflow

When adding a `\parencite{}` citation:

1. **Check `lib.bib` first** — grep the project's local file for an existing key.
2. **Search Zotero** with `zoteroutil search "<terms>"` — the reference may be in the library but not yet exported.
3. **Add if missing** with `zoteroutil add --type ... --title ... --author ... --date ...`.
4. **Refresh `lib.bib`** with `zoteroutil refresh-lib <project-path>` (requires Zotero + Better BibTeX running).
5. **Cite** the key in `\parencite{key}` and always provide the full surrounding text block in your edit (so the citation lands in context, not as a dangling marker).

Use the `/zotero` skill for the full command surface. For porting markdown-with-URLs notes into a citation-clean LaTeX chapter, use `/md-to-latex-cite`.

### Accessibility (PDF/UA-2)

Board-distributed and externally-facing strategic plans should enable PDF/UA-2 tagging at the top of the master `.tex`:

```latex
\DocumentMetadata{tagging=on, pdfversion=2.0, pdfstandard=ua-2}
\documentclass[12pt,oneside]{book}
```

Note: `\DocumentMetadata` requires LaTeX ≥ 2024-06; some constructs (e.g., `\include` of glossary files) interact poorly with tagging and must be `\input`-ed instead.

### Research Priority

Before writing any content section:

1. **Obsidian semantic search first** — `obsearch "<query>"` or `obsearchf "<query>"` against the calliope vault. The vault contains vetted organization-specific knowledge (BH/MHS context, prior strategic plans, vendor decisions, research notes).
2. **Project's own `research/` directory** — usually contains source PDFs and analysis notes specific to the deliverable.
3. **Web search / external sources** — supplement only after exhausting local knowledge.

Always prefer institutional knowledge over general web sources — it aligns with our terminology, vendor relationships, and prior commitments.

### Per-Project CLAUDE.md

Every LaTeX project has a `CLAUDE.md` covering at minimum:

- Build commands (verbatim from the standard above)
- Citation style (APA vs Vancouver) and bibliography conventions
- Document architecture — what each chapter/section file contains
- Project-specific naming (e.g., "chapters are called 'Section' via `\renewcommand{\chaptername}{Section}`")
- Custom colors and any deviation from the standard palette
- VS Code task wiring if present

`Common-Elements/CLAUDE.md` is the source-of-truth template; `sync-templates.sh` propagates it.

### VS Code Integration

Standard project `.vscode/` directory:

- **`tasks.json`** — build tasks mapped to `latexbuild` (Full Build / Quick Build / Clean)
- **`settings.json`** — file-explorer exclusions for `.aux`/`.bbl`/etc., word wrap on for `.tex` files
- **`latex.code-snippets`** — snippets for project-specific commands (e.g., `trav-*` color prefixes)

### Editing Workflow

For multi-pass editing of finished drafts, drive the `/editor-manager` skill — it orchestrates the full editor pipeline (`editor-content` → `editor-cite` → `editor-development` → `editor-structural` → `editor-line` → `editor-copy` → `editor-visual` → `editor-proofreader`) with session persistence. For single-pass review, invoke the specific editor skill directly.

For technical content (IT architecture, product capabilities, standards references), use `/editor-technical` before line editing — factual errors compound through later passes.

## Microsoft Office

Two production paths; pick deliberately:

### Python (preferred for repeatable output)

Use the `office-files` skill:

- **Word:** `python-docx` via `uv run`
- **Excel:** `openpyxl` via `uv run`
- **PowerPoint:** `python-pptx` via `uv run`

Scripts go in the project's repo so the document is regenerable. Use this whenever the document will be regenerated more than once, or when output must be deterministic (auto-generated tables, programmatic charts, branded section layouts).

### MCP Servers (preferred for in-session ad-hoc work)

- **Word:** `word-document-server` MCP
- **PowerPoint:** `ppt` MCP
- **Excel:** `excel` MCP

Use these when editing a single existing document inside an active Claude conversation — no script artifact, just direct manipulation.

### Presentations

Use the `/presentation` skill for PowerPoint scaffolding — it handles BH/MHS/USA brand templates and the common slide patterns. For LaTeX/PDF presentations, use `Beamer` + the matching `MH-Presentation-Template`.

### Brand Compliance

Office files for BH/MHS audiences must follow the brand guides:

- `/broward-health-branding` — colors, fonts (Raleway), logo usage, tone, PowerPoint/Word/email templates
- `/memorial-healthcare-branding` — colors, fonts (Montserrat), logo usage, tone, PowerPoint/Word/email templates

Don't improvise brand colors or pick "close-enough" fonts. The brand skills cite the official PDFs (e.g., `BHC_BrandStyleGuide.pdf v1.3`).

## Document Conversion

Use the `/doc-convert` skill for cross-format conversion: Word↔Markdown, Markdown↔LaTeX, image→text (OCR), batch image format conversion. Don't hand-roll pandoc invocations — the skill handles the brand-aware variants.

## Anti-Patterns to Avoid

- `\documentclass{memoir}` — we migrated off; use `article` / `book` / `beamer`
- `pdflatex` — breaks `fontspec` and brand fonts; always XeLaTeX
- Hand-running `xelatex` / `biber` cycles — use `$scripts/latexbuild`
- `\cite{...}` — always `\parencite{...}` (the APA/Vancouver styles require parenthetical form)
- Adding entries directly to `lib.bib` — round-trip through Zotero so other projects benefit
- Improvised RGB values for BH/MHS colors — use the named tokens from the brand skills
- Loading `hyperref` anywhere except last in the preamble
- Hyphenation enabled in body text — `\hyphenpenalty=10000` everywhere
- Editing `Common-Elements/` files without then running `sync-templates.sh`
- Cherry-picking template files instead of copying the whole directory (loses `.gitignore`, `.claude/`)
- Hard-coded absolute paths in `.tex` (figures via `\graphicspath`, bib via `\addbibresource{lib.bib}`)
- Committing build artifacts (`.aux`, `.bbl`, `.log`, `.synctex.gz`, etc.) — the standard `.gitignore` handles this
- Generating brand-sensitive Office files without consulting the brand skill first
- Using Word/PowerPoint for documents that will be printed or distributed as final-form PDF — LaTeX wins on typography every time
