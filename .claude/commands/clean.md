---
description: Run agent-cleaner — audit this repo to a standard of excellence (safe, evidence-based, scales to large repos)
argument-hint: "[optional: path or scope to focus on]"
---

You are running **agent-cleaner** on this repository. Bring it up to a standard of excellence —
safely, with evidence, and without lowering the bar when the repo is large.

If the full agent-cleaner docs are present (`STANDARD.md`, `PROTOCOL.md`, `WORKER.md`, `templates/`),
read and follow them for complete detail. This command is a self-contained condensation.

Optional focus from the user: $ARGUMENTS

## Five rules that never bend
1. **The standard is invariant** — a big/messy repo changes your execution strategy (shard,
   plan, parallelize, reset context), never what you demand.
2. **Detect before you change** — use the repo's existing tools and commands; install only
   missing standard gates, minimally; never migrate package managers or rewrite architecture.
3. **Evidence over judgment** — every fix is verified by re-running its gate and capturing output.
4. **Three dispositions, no guessing** — every issue ends as FIXED, NEEDS HUMAN DECISION, or
   INTENTIONAL.
5. **Safety first** — work on the `chore/agent-cleaner` branch; no force-push, hard-reset, or
   deletion of unmerged branches without flagging.

## The loop
0. **Safety baseline** — confirm git repo; record branch + HEAD; create `chore/agent-cleaner`; clean tree.
1. **Measure** — files, LOC, stack, existing tooling, canonical commands (CI/Makefile/scripts).
   Decide **QUICK** (fits in context → one pass) or **SCALE** (too big → orchestrate).
2. **Tooling bootstrap** — detect declared stack; install only missing standard gates; log each.
3. **Plan** — write `.agent-cleaner/PLAN.md`: tiers (config → repo-wide format → parallel modules
   → docs/tests → integration); parallel only across disjoint write-surfaces.
4. **Execute** —
   - QUICK: run gates, apply safe fixes, reconcile docs, verify each fix inline.
   - SCALE: become an orchestrator. Dispatch scope-locked subagents for non-overlapping chunks;
     ingest only small structured summaries; keep `.agent-cleaner/STATE.md` as the system of
     record; reset context intentionally with a written handoff before drift.
5. **Verify** — every chunk passes its gate with captured evidence; then run global gates
   (format, lint, types, tests, secret scan, docs spot-check).
6. **Report** — FIXED (with verifying commands) / NEEDS HUMAN DECISION (with options) /
   INTENTIONAL (with evidence) + tooling added + token ledger. Leave a clean branch.

## The bar (apply per stack; defaults only when the repo is unopinionated)
- **Builds & runs** from a documented command; lockfile committed.
- **Format** tool-enforced (`ruff format` / Prettier / `gofmt` / `rustfmt`).
- **Lint** zero errors (`ruff check --fix` / ESLint); import order included.
- **Types** pass (mypy by default; ty/pyright/tsc if already adopted).
- **Tests** run and pass; no unexplained skips.
- **Docs match reality** — README quickstart actually works.
- **Hygiene** — no committed secrets, no giant logs/artifacts, sane `.gitignore`.
- **Deps & security** — lockfile consistent; known-vuln deps surfaced; unused deps flagged.
- **Git** — clean tree; unmerged branches never deleted.
- **Structure** — dead code flagged; TODO/FIXME triaged.

Begin with Phase 0 now. Do not skip measurement — the QUICK/SCALE choice depends on it.
