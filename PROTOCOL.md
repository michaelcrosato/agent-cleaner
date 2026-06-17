# PROTOCOL — the engine

This is the full operating procedure behind [AGENTS.md](AGENTS.md). It defines the phases, the
QUICK vs SCALE decision, the orchestrator role, the tier/DAG plan, and how to manage context so
the same bar holds from a 50-file repo to a 50,000-file monorepo.

Read [STANDARD.md](STANDARD.md) first — that's *what* you're enforcing. This is *how*.

---

## Phase 0 — Safety baseline

Before touching anything:

- Confirm it's a git repository. If not, say so and ask whether to `git init` before proceeding.
- Record the current branch and HEAD commit — this is your revert anchor.
- Ensure a clean working tree (commit-in-progress work is the user's; stash or stop and flag).
- Create and switch to a working branch: `chore/agent-cleaner` (never operate on `main`/`master`
  directly).
- Hard rules for the entire run: **no force-push, no history rewrite, no hard-reset, no deletion
  of unmerged branches** without an explicit human decision.

## Phase 1 — Measure

Run [`scripts/measure.sh`](scripts/measure.sh) (or the equivalent commands directly) to capture:

- File and directory counts; total LOC; the largest files.
- The stack(s): from manifests/lockfiles (`pyproject.toml`, `package.json`, `go.mod`,
  `Cargo.toml`, …).
- **Existing tooling**: tool configs (`[tool.ruff]`, `.pre-commit-config.yaml`, `.eslintrc`,
  `biome.json`, `mypy.ini`, `tsconfig.json`), and **canonical commands** (CI workflows,
  `Makefile`/`justfile`, `package.json` scripts). These tell you the repo's *own* definition of
  its gates — prefer them.
- **Toolbelt availability**: which efficiency tools are installed in *your* environment
  (`rg`, `ast-grep`, `fd`, `tokei`, `biome`, …). `measure.sh` prints this. See
  [TOOLBELT.md](TOOLBELT.md) — knowing what's on the box decides what you use, install, or request.
- A rough size/effort estimate.

**Then decide the mode:**

- **QUICK** — the repo comfortably fits in your effective context (not the advertised maximum —
  the size at which you stay reliable) and the audit is one coherent pass.
- **SCALE** — it doesn't. You'll orchestrate (Phase 4, SCALE path).

If unsure, start QUICK; promote to SCALE the moment you notice you can't hold the whole picture
reliably. Promotion is cheap; a shallow audit is not.

## Phase 2 — Tooling bootstrap

Detect-before-install, always. Two tracks (full detail in [TOOLBELT.md](TOOLBELT.md)):

**Gates** (required — they enforce the Standard):
1. Use the repo's declared tools and canonical commands as the gates. If the repo says how it
   lints/tests, that *is* the gate.
2. Install only **missing standard gates**, minimally, as **repo dev dependencies** aligned to
   the stack (e.g. add Ruff + mypy + pytest to an unopinionated Python repo that has none;
   Biome or Prettier+ESLint+tsc for JS/TS). Pin them.
3. **Record every install** in `PLAN.md` so a fresh environment is reproducible.
4. Do **not** migrate package managers, swap working tools, or "modernize" a deliberate setup.
   If the existing tooling is unusual but functional, that's likely INTENTIONAL — treat it so or
   raise a NEEDS HUMAN DECISION; don't unilaterally replace it.

**Accelerants** (optional — they make you fast and cheap: `rg`, `ast-grep`, `fd`, `tokei`):
5. These install into **your environment**, not the repo, and are never committed. If one is
   missing and useful, install it non-interactively via the platform package manager; if that
   needs elevation/network you lack, **request** it from the user (name the exact command) and
   fall back to the host's built-in search/read meanwhile. Never block the audit on an accelerant.

Default stack reference is in [STANDARD.md](STANDARD.md); the toolbelt and the retrieval-funnel /
guarded-edit discipline are in [TOOLBELT.md](TOOLBELT.md). Tooling additions are themselves part
of the audit trail.

## Phase 3 — Plan

Write `.agent-cleaner/PLAN.md` (from [templates/PLAN.md](templates/PLAN.md)). Partition the work
into a **dependency-aware tier model** — this is what makes parallelism safe:

| Tier | Work | Concurrency |
|---|---|---|
| **1** | Global/core config, cross-cutting types & interfaces | Sequential, first |
| **2** | Repo-wide mechanical passes (formatting, import-sort) | Once, early, sequential — avoids diff/merge conflicts across parallel workers |
| **3** | Per-module deep audit | **Parallelizable** — chunks must have disjoint write surfaces |
| **4** | Docs ↔ code reconciliation, tests | Parallel where independent |
| **5** | Final integration gates + report | Sequential, last |

Rules:
- **Parallel width = the number of Tier-3 chunks whose dependencies are satisfied and whose file
  write-surfaces do not overlap**, capped by available resources. Two workers must never be able
  to edit the same file.
- Do the repo-wide formatting pass (Tier 2) *before* fanning out, so parallel workers aren't all
  reformatting the same lines.
- In **QUICK** mode the plan legitimately collapses to a single chunk. Keep it that simple.

## Phase 4 — Execute

Throughout, work the [TOOLBELT.md](TOOLBELT.md) discipline: search for paths + counts before
reading; pull only the line spans you need; use `ast-grep` when regex starts matching the wrong
thing; and run the fast linter on each edited file before moving on (guarded edit loop). Avoiding
full-file dumps is what keeps this affordable at scale.

### QUICK path
Do the work inline: run the gates, apply safe fixes, reconcile docs, verify each fix by re-running
its gate. Record findings directly in `STATE.md`. One pass, honest evidence, done.

### SCALE path — you are now an orchestrator
Your context is a scarce resource; spend it on coordination, not file contents.

**You (orchestrator) DO:** own `PLAN.md` + `STATE.md`; decide what's ready to run; dispatch
workers; run acceptance gates; integrate; update the token ledger; reset context on schedule.

**You (orchestrator) DO NOT:** read source files yourself, implement fixes by hand, or ingest raw
worker transcripts. You relay scope + standard; you receive only small structured summaries.

**Dispatch loop:**
1. Select Tier-3 chunks whose deps are met and whose write-surfaces are disjoint (up to parallel
   width).
2. For each, spawn a scope-locked worker per [WORKER.md](WORKER.md): hand it exact paths, the
   gate commands, and the standard. Nothing else.
3. Accept a worker's result **only** with evidence: gate command + passing output. Reject and
   re-dispatch (or re-shard smaller) otherwise.
4. Write the outcome to `STATE.md`. Keep tool outputs and file contents **out** of your context —
   they live in artifacts/state, re-fetchable on demand.
5. Repeat until all Tier-3 chunks are resolved, then proceed to Tiers 4–5.

**Context management (the part that makes SCALE actually work):**
- Treat `STATE.md` as the system of record. Chat history is never your memory.
- Prefer **clearing re-fetchable tool output** over lossy summarization. Compact only when needed.
- Reset/clear context intentionally before drift — well before the hard limit (think ~60–75% fill).
- Before any reset, write a **handoff summary** to `STATE.md`: what's done, what's in flight, what's
  next, and exactly how to resume. A new session reads only `STATE.md` and continues.

**When a chunk fights back:** don't lower the bar and don't skip it. Re-shard it smaller and retry.
Track whether failures correlate with context fill (an *implementation* problem — fix the
approach) or not (a genuinely *hard* knot — escalate to NEEDS HUMAN DECISION). If an approach
isn't working, try another; eventually you'll know whether it's the problem or your method.

## Phase 5 — Verify (acceptance)

- A chunk is "done" only when its gate passes with **captured evidence**.
- After integration, run the **global gates** over the whole repo: format check, lint, type check,
  full test suite, secret scan, and a docs spot-check (does the README quickstart still work?).
- Any regression introduced during the run is yours to fix before reporting.

## Phase 6 — Report

Produce the final report (and leave it in `STATE.md`):

- **FIXED** — grouped by category, each with the verifying command + result.
- **NEEDS HUMAN DECISION** — each with context, options, and a recommendation.
- **INTENTIONAL** — what was respected and the evidence it was deliberate.
- **Tooling added** — every install, so the environment is reproducible.
- **Token ledger** — estimated vs actual per chunk (calibrates the next run).
- **Repo state** — the working branch, clean tree, and the exact commands to re-verify.

Done means: every in-scope item resolved to one of the three dispositions, global gates run with
results captured, and nothing silently skipped. If coverage was bounded anywhere, say so plainly.

---

## The orchestrator in one line

A release captain and scheduler: it builds a dependency-aware plan, fans out the maximum *safe*
parallel work that plan allows, and accepts nothing without evidence — keeping its own context
clean so it never becomes the bottleneck.
