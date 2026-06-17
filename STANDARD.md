# The Standard of Excellence

This is the bar. It does not change with repo size, language, or how messy the starting point
is. A large repo changes the *execution strategy*, never the standard.

Every category below resolves to one of three **dispositions**. Nothing is left vague.

| Disposition | Meaning |
|---|---|
| **FIXED** | Brought to standard and **verified** by re-running the relevant gate. The report includes the command and its passing output. |
| **NEEDS HUMAN DECISION** | Ambiguous, risky, destructive, or design-level. Described clearly, with options and a recommendation. **Never guessed.** |
| **INTENTIONAL** | The repo documents a reason (config comment, docs, ADR, CI note). Respected and recorded — not "fixed." |

> **Detect before you change.** Where this document names a default tool, it applies only when
> the repo is unopinionated. An existing, working choice is always respected. Introducing a new
> standard tool is allowed when one is genuinely missing — and every such addition is logged in
> the plan.

---

## The categories

### 1. Builds & runs
- A clean checkout installs and runs from a **documented command**.
- A lockfile / pinned environment exists and is committed (e.g. `uv.lock`, `poetry.lock`,
  `package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, `go.sum`).
- No "works only on the author's machine" assumptions left undocumented.

### 2. Formatting
- Formatting is consistent and **tool-enforced**, not hand-maintained.
- Defaults when unopinionated: `ruff format` (Python), Biome (fast Rust-based JS/TS; Prettier if
  the repo already uses it), `gofmt` (Go), `rustfmt` (Rust).
- Run in check mode for verification; apply in fix mode as a one-time, repo-wide mechanical pass.

### 3. Linting
- Zero lint **errors** on the agreed ruleset. Warnings are triaged, not ignored.
- Default when unopinionated: `ruff check --fix` (Python; covers Flake8/isort/pyupgrade/etc.),
  Biome or ESLint (JS/TS — honor whichever the repo already uses).
- Import ordering is part of this gate (`ruff check --select I --fix`), since formatters don't
  sort imports.

### 4. Types
- The type checker passes where the language supports it.
- Defaults: **mypy** (Python — ty/pyright honored if already adopted), `tsc --noEmit` (TS).
- New `# type: ignore` / `any` escapes must be justified or flagged.

### 5. Tests
- The test suite **runs and passes** from a documented command.
- No tests skipped without a stated reason. Coverage is not silently regressed.
- If there are no tests at all in a codebase that clearly should have them, that's a
  **NEEDS HUMAN DECISION**, not a silent pass.

### 6. Docs match reality
- The README quickstart **actually works** when followed literally.
- Documented commands, scripts, env vars, and file paths exist.
- No references to deleted modules, renamed flags, or moved files.
- Version numbers, badges, and CHANGELOG are coherent with the current state.

### 7. Repo hygiene
- **No secrets** committed (keys, tokens, `.env` with real values). A secret scan is run.
- No giant logs, build artifacts, caches, or stray binaries tracked in version control.
- `.gitignore` is sane and covers the stack's usual artifacts.
- No surprising oversized files; large assets are justified or flagged.

### 8. Dependencies & security
- Lockfile committed and consistent with the manifest.
- Known-vulnerable dependencies are surfaced (e.g. `pip-audit`, `npm audit`, `osv-scanner`)
  and either updated or flagged.
- Obviously unused dependencies are flagged (not silently deleted — removal can break things).

### 9. Git hygiene
- Work happens on a branch; the working tree is clean when the run ends.
- Merged local branches may be flagged for cleanup. **Unmerged** branches are never deleted.
- No force-push, no history rewriting, no hard-reset without an explicit human decision.

### 10. Structure & dead code
- Obvious dead code and unreferenced files are flagged (removed only when clearly safe).
- `TODO` / `FIXME` are triaged: actioned, ticketed, or flagged — not left as untracked debt.
- Project layout is consistent with the stack's conventions.

---

## The invariant, restated

When a repo is huge, the temptation is to skim, sample, or declare "good enough." That is the
one thing agent-cleaner does not do. Full coverage is non-negotiable. If holding the bar is
hard, the response is to **decompose better and continue** — smaller chunks, isolated workers,
durable state, fresh context — until every item is FIXED, NEEDS HUMAN DECISION, or INTENTIONAL.

We don't lower our standards when faced with challenges. We raise our implementation.
