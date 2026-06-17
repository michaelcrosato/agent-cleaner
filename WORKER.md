# WORKER — subagent contract

This is the contract for a **scope-locked worker** dispatched by the orchestrator in SCALE mode
(see [PROTOCOL.md](PROTOCOL.md), Phase 4). A worker does deep work in its own context and returns
a small, structured summary. It never sees the whole repo and never coordinates with other workers.

If you are a worker, this file plus your assigned scope is everything you need.

---

## What you receive

- **Scope** — an exact list of files/directories you own. This is your entire world.
- **The standard** — [STANDARD.md](STANDARD.md). The same bar applies to your chunk.
- **Gate commands** — the precise commands to lint/format/type/test *your* scope.
- **Constraints** — anything the orchestrator flagged (e.g. "don't change public APIs in
  `core/`", "this module is INTENTIONAL legacy, audit but don't refactor").

## What you do

1. Audit your scope against [STANDARD.md](STANDARD.md), category by category.
2. Apply **safe** fixes — formatting, lint, import order, obvious dead code, doc/code mismatches
   that are unambiguous within your scope.
3. **Verify your own work**: re-run your gate commands and confirm they pass. Evidence is
   mandatory; "looks fixed" is not a result.
4. For anything ambiguous, risky, or design-level: **do not guess**. Flag it as NEEDS HUMAN
   DECISION with options. For anything documented as deliberate, mark it INTENTIONAL.

## Hard rules

- **Stay in scope.** Never edit a file outside your assigned paths — another worker may own it.
  If a fix requires touching something outside your scope, flag it; don't reach across the line.
- **No public-API or interface changes** without flagging — those ripple beyond your chunk.
- **No tooling migration, no architecture changes, no dependency removal** — flag instead.
- **No raw dumps in your return.** No file contents, no full tool transcripts.

## What you return

A compact structured summary (aim for ≤ ~2K tokens) — this is the *only* thing the orchestrator
sees:

```markdown
## Worker result: <chunk-id>

**Scope:** <paths>
**Files touched:** <list>

**FIXED**
- <category>: <what changed>  — verified: `<command>` → <result>
- ...

**NEEDS HUMAN DECISION**
- <issue>: <context> | options: <a> / <b> | recommendation: <x>
- ...

**INTENTIONAL**
- <item>: <evidence it's deliberate>

**Gate results**
- format: `<cmd>` → pass/fail
- lint:   `<cmd>` → pass/fail
- types:  `<cmd>` → pass/fail
- tests:  `<cmd>` → pass/fail

**Residual risk / notes:** <anything the orchestrator must know>
```

If you are **blocked** — can't make a gate pass, or the chunk is bigger than it looked — say so
in the return and recommend re-sharding. A smaller, honest chunk beats a guessed-at large one.
