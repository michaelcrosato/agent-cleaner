# TOOLBELT — the right tools for the job

Standard human shell tools (`cat`, `sed`, raw `grep`) are token-bleeders. Dumping a whole file
or wall-to-wall match results into context destroys grounding and burns budget. The right tools
are the single highest power-to-weight intervention available: bounded search, structural
matching, and millisecond linters.

agent-cleaner sorts tooling into **three tiers**, each handled differently. This is what the
protocol means by "review the tools available, then install or request what's missing."

---

## Tier A — GATES (required: they enforce the Standard)

The deterministic quality gates: `ruff` + `mypy` + `pytest` (Python); `biome` **or**
`prettier` + `eslint` + `tsc` (JS/TS); `gofmt` + `go vet` + `go test` (Go); etc.

- **Review** in Phase 1, **act** in Phase 2.
- If a needed gate is missing, **install it as the repo's own pinned dev-dependency** and record
  it in `PLAN.md`. Gates become part of the repo's reproducible tooling — they belong *in* the repo.
- **Never migrate** an existing, working gate (Prettier→Biome, poetry→uv, …). That's a
  `NEEDS HUMAN DECISION`, not a unilateral change.

## Tier B — ACCELERANTS (optional: they make the agent fast and cheap)

These live in the **agent's environment**, not the repo. They are never committed and never block
the audit. Review availability → use if present → install if cheap/safe/non-interactive →
otherwise request from the user (naming the exact command) and degrade to the fallback meanwhile.

| Tool | Use it for | How to get it | Fallback if absent |
|---|---|---|---|
| **ripgrep** (`rg`) | Fast, `.gitignore`-aware text search; return filenames + hit counts before any content | Usually bundled with the agent; else `winget`/`scoop`/`brew`/`apt` | Host's built-in search; `grep -rl` |
| **ast-grep** (`sg`) | Structural AST search & safe multi-file codemods — escalate here the moment a regex starts matching comments, strings, or the wrong syntactic position | `npm i -g @ast-grep/cli`, `cargo install ast-grep`, `brew install ast-grep` | `rg` + targeted edits |
| **fd** | Fast file discovery | pkg manager | `find` / host glob |
| **tokei** | LOC-by-language for measurement | pkg manager | `wc` fallback in `measure.sh` |
| **gitleaks** / **trufflehog** | Secret scanning gate | pkg manager | flag "no scanner available" in report |

> `biome` is special: it doubles as a **gate** (Tier A) and an accelerant. Prefer it as the fast
> default for *unopinionated* JS/TS repos; honor an existing Prettier/ESLint setup.

## Tier C — HOST-PROVIDED (assume; do not rebuild)

Frontier agents (Claude Code, Cursor, Codex, SWE-agent, …) already provide bounded I/O:

- **Windowed file reads** — open a 100-ish-line span, not the whole file.
- **Ripgrep-backed search** that returns paths/counts before content (the retrieval funnel,
  layer 1).
- **Exact-string block editors** — precise target-string replacement, not inline `sed`.

**Use these.** agent-cleaner does not reimplement them — shipping shell wrappers for windowed
viewers or `str_replace` editors would be redundant and a step backward. If a host genuinely
lacks bounded I/O, that is a limitation of the host, not work for this package.

---

## When / where / how / why

- **WHEN** — Phase 1 reviews availability (`scripts/measure.sh` prints a toolbelt report).
  Phase 2 acts on the gaps.
- **WHERE** — gates install into the **repo** (committed, pinned); accelerants install into the
  **agent environment** (not committed).
- **HOW** — prefer the platform package manager, non-interactively. If installation needs
  elevation or network access you don't have, **request** it from the user with the exact command
  and proceed with the fallback in the meantime. Never stall the audit on an accelerant.
- **WHY** — every full-file dump you avoid and every false-positive match you never read is
  tokens, latency, and cost saved. On large repos this is the difference between an audit that
  finishes and one that drowns in its own context.

## Working discipline (the retrieval funnel + the guarded edit loop)

1. **Search before you read.** Get paths + hit counts first (host search / `rg`); then pull only
   the exact line spans you need with a windowed read. Never `cat` a large file into context.
2. **Structural over textual.** When a regex starts catching comments, strings, or the wrong
   position, switch to `ast-grep`. For repeated mechanical fixes across many files, an `ast-grep`
   rule is safer and cheaper than hand-editing each site.
3. **Guarded edit (inner loop).** After each edit, run the fast linter/formatter on *just that
   file*. If it fails, fix or revert immediately — don't wait for CI to catch a syntax error and
   don't pile edits on top of a broken state.
4. **Bounded edits.** Change code via precise target-string replacements, not blind `sed`/`awk`.
