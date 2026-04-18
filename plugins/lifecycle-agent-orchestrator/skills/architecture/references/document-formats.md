# Technical Document Format Standard

When creating technical design documents, ADRs, or other architectural documentation, produce the document in up to **three formats** depending on the audience and distribution needs. The user may request one, two, or all three.

## Formats

### 1. Markdown (`.md`) — Source of Truth

**Purpose:** Version-controlled, git-friendly, renders on GitHub/GitLab.

**When to use:** Always. This is the canonical format that lives in the repository.

**Characteristics:**
- Standard GitHub-flavored markdown
- ASCII art for diagrams (monospace-dependent)
- Tables use pipe syntax
- Code blocks with language fences
- Works in code review, diffs, and terminal rendering

**Filename:** `YYYY-MM-DD-<topic>-design.md`

**Limitations:**
- ASCII diagrams break in proportional fonts (Google Docs, Word, PDF)
- No interactive features (collapsible sections, navigation)
- Basic styling only

---

### 2. Interactive HTML (`.html`) — Browser Viewing

**Purpose:** Rich interactive document for browser-based reading and presentation.

**When to use:** When the document will be shared via URL, viewed in browsers, or presented in meetings.

**Characteristics:**
- Sticky sidebar table of contents with scroll-spy (active section highlighting)
- Collapsible `<details>/<summary>` sections for long documents
- SVG diagrams for architecture components
- Styled cards for ADRs, strategies, and callouts
- Smooth scrolling on anchor navigation
- Mobile responsive (3 breakpoints: tablet, small screen, phone)
- Print-friendly CSS (`@media print`): expands all sections, ink-friendly colors, page breaks
- Self-contained — no external dependencies except Google Fonts

**Filename:** `YYYY-MM-DD-<topic>-design.html`

**Key implementation notes:**
- Use CSS `<style>` block (not inline) for maintainability
- Use `<details class="section-collapse">` for collapsible sections
- Add `scroll-behavior: smooth` on `<html>`
- Add `beforeprint` JS event listener to auto-expand collapsed sections
- SVG diagrams should have `viewBox` and `max-width: 100%` for responsive scaling
- Include 3 responsive breakpoints:
  - ~1100px: narrow sidebar
  - ~860px: hide sidebar, stack columns
  - ~480px: phone-optimized typography
- Print styles: hide sidebar, expand all sections, black text, light backgrounds, `break-inside: avoid` on cards/tables

**Limitations:**
- Does not import cleanly into Google Docs (sidebar, collapsible, SVG, CSS all stripped)
- Requires a browser to view

---

### 3. Google Docs HTML (`.gdoc.html`) — Document Sharing

**Purpose:** Clean import into Google Docs for collaborative editing, commenting, and sharing with stakeholders who don't use GitHub.

**When to use:** When the document needs to be shared with non-engineering stakeholders, reviewed in Google Docs, or exported as PDF from Google Docs.

**Characteristics:**
- ALL styles are inline (`style=""` on every element) — no `<style>` blocks, no CSS classes
- Flat document structure — no `<details>`, `<summary>`, `<nav>`, `<aside>`
- No JavaScript
- No SVG — diagrams rendered as styled HTML tables with borders that approximate the architecture
- Table of Contents as a simple numbered list with `<a href="#id">` anchor links
- ADR cards as bordered `<div>` with inline `border`, `padding`, `background-color`
- Code blocks as `<pre>` with inline monospace font and background color
- Tables with inline `border-collapse`, `border`, `padding` on every cell
- Colors used sparingly — section card headers, strategy cards, callout borders

**Filename:** `YYYY-MM-DD-<topic>-design.gdoc.html`

**What survives Google Docs import:**
- `<h1>` through `<h6>` → Google Docs Heading styles (auto-generates outline)
- `<table>` with inline borders → native Google Docs tables
- `<strong>`, `<em>`, `<code>` → bold, italic, monospace
- `<pre>` → monospace block (background color may be stripped)
- Inline `color`, `background-color`, `font-weight`, `font-family` → mostly preserved
- `<a href="#id">` anchor links → clickable within the doc
- `<img src="...">` → embedded images (if reachable URL)

**What Google Docs strips:**
- `<style>` blocks, CSS classes, external stylesheets
- `<details>`, `<summary>`, `<nav>`, `<svg>`
- JavaScript
- CSS Grid, Flexbox, `position: sticky/fixed`
- `border-radius` (borders become square)
- Most `margin`/`padding` values (Google Docs uses its own spacing)

**Key implementation notes:**
- Put `style="border-collapse: collapse"` on every `<table>`
- Put `style="border: 1px solid #999; padding: 8px 12px"` on every `<th>` and `<td>`
- For diagrams, use nested tables or simple text-based box layouts with borders
- Test the import: upload to Google Docs and verify formatting before distributing

**Import steps:**
1. Open Google Docs
2. File → Open → Upload
3. Select the `.gdoc.html` file
4. Google Docs converts it automatically
5. Verify: check heading outline, table formatting, code blocks, colors

---

## How to Choose

| Need | Format(s) |
|------|-----------|
| Git repository documentation | `.md` only |
| Engineering team review | `.md` + `.html` |
| Stakeholder presentation / share-out | `.html` or `.gdoc.html` |
| Google Docs collaboration | `.gdoc.html` |
| All audiences | All three |

**Default:** When creating a new design document, always create the `.md` version. Ask the user if they also need `.html` and/or `.gdoc.html` versions.

**Regeneration:** If a document is updated, before regenerating all existing format versions to keep them in sync, ask the user if they also need `.html` and/or `.gdoc.html` versions updated. The `.md` is the source of truth — the HTML versions are derived from it.

---

## File Location

All design documents go in `docs/specs/`:

```
docs/specs/
├── 2026-04-02-example-design.md          # Markdown (source of truth)
├── 2026-04-02-example-design.html        # Interactive HTML (browser)
└── 2026-04-02-example-design.gdoc.html   # Google Docs import
```
