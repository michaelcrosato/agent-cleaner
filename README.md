# agent-cleaner

**Point any frontier coding agent at a repository and bring it up to a defined standard of excellence — safely, with evidence, and without lowering the bar when the repo gets large.**

agent-cleaner is not a framework or a CLI. It's a small, tool-agnostic **prompt + protocol package**: a set of Markdown contracts the agent reads and follows, plus two optional helper scripts. The intelligence lives in the agent; this repo gives it a disciplined operating procedure.

It is designed to be **fast on small repos and to scale to the largest ones** by changing *how* it works (shard, plan, fan out subagents, reset context) — never *what* it demands (the standard is invariant).

---

## What it does

Given a repository, the agent will:

1. **Establish a safety baseline** — work on a branch, never force-push or hard-reset without flagging.
2. **Measure** the repo (size, stack, existing tooling, canonical commands) and pick a mode: **QUICK** or **SCALE**.
3. **Bootstrap tooling** — detect the existing stack first; install only missing *standard* gates, minimally, without migrating what already works.
4. **Run the deterministic gates** — format, lint, types, tests, secret scan — and fix what's safely fixable.
5. **Reconcile docs with reality** — the README quickstart should actually work; documented commands should exist.
6. **Report** every item under one of three dispositions:
   - **FIXED** — brought to standard and verified by re-running the gate.
   - **NEEDS HUMAN DECISION** — ambiguous, risky, or design-level; described with options, never guessed.
   - **INTENTIONAL** — the repo documents a reason; respected and recorded.

The full bar is in [STANDARD.md](STANDARD.md). The engine that delivers it is in [PROTOCOL.md](PROTOCOL.md).

---

## Quickstart

### Claude Code
Copy the command into your repo (or `~/.claude/commands/`) and run it:

```
cp .claude/commands/clean.md /path/to/your-repo/.claude/commands/
cd /path/to/your-repo
# then in Claude Code:
/clean
```

### Any other agent (Codex, Cursor, Copilot, Aider, Windsurf, …)
Clone this repo, then from your target repo tell the agent:

> Read and follow the operating contract at `/path/to/agent-cleaner/AGENTS.md`. Apply it to **this** repository.

Agents that read `AGENTS.md` natively (most do, as of 2026) can also have it vendored directly into the target repo.

### Single file (paste one prompt)
When it makes more sense to inject one prompt than to bring in the whole repo, use
[PROMPT.md](PROMPT.md) — a fully self-contained distillation of the entire system in under 4,000
characters. Paste it as your first message, then: *"Apply this to the repository in the current
directory."* It depends on no other file.

---

## How it works

```
  Phase 0  Safety baseline   ── branch, record HEAD, never touch main directly
  Phase 1  Measure           ── size, stack, tooling, commands  →  choose QUICK | SCALE
  Phase 2  Tooling bootstrap ── detect before install; never migrate silently
  Phase 3  Plan              ── tier/DAG of chunks; write .agent-cleaner/PLAN.md
  Phase 4  Execute           ── QUICK: inline   |   SCALE: fan out scope-locked workers
  Phase 5  Verify            ── every chunk passes its gate, with evidence
  Phase 6  Report            ── FIXED / NEEDS DECISION / INTENTIONAL + token ledger
```

**QUICK mode** (small/medium repos): one pass, gates, fix, verify. Minutes, not ceremony.

**SCALE mode** (large repos): the agent becomes an orchestrator. It writes a dependency-aware plan, dispatches scope-locked [workers](WORKER.md) for chunks that don't overlap, ingests only small structured summaries, and treats `.agent-cleaner/STATE.md` as the system of record so it can reset context and resume without losing the thread. This is the [Ralph-loop](https://github.com/iannuttall/ralph) pattern applied to auditing: durable on-disk state, fresh iterations, deterministic verification.

The promotion from QUICK to SCALE is a *measurement* decision, not a guess — see [PROTOCOL.md](PROTOCOL.md).

---

## What it will NOT do

Purpose-built means knowing where to stop. agent-cleaner will not:

- Migrate package managers or replace working tooling (uv↔poetry, npm↔pnpm, etc.) — it flags this as `NEEDS HUMAN DECISION`.
- Rewrite architecture or "improve" design beyond the standard.
- Delete unmerged branches, force-push, or make irreversible git changes without flagging.
- Touch anything the repo explicitly documents as intentional.
- Pretend a gate passed. Every `FIXED` is backed by a re-run with output.

---

## Repository layout

```
agent-cleaner/
├── README.md              you are here
├── PROMPT.md              the whole system distilled into one self-contained prompt (<4000 chars)
├── AGENTS.md              front door — the operating contract any agent follows
├── STANDARD.md            the invariant bar + the three dispositions
├── PROTOCOL.md            the engine — phases, QUICK vs SCALE, orchestration, context mgmt
├── WORKER.md              subagent contract — scope-locked in, structured summary out
├── TOOLBELT.md            the right tools (gates vs accelerants vs host-provided) + efficiency discipline
├── templates/
│   ├── PLAN.md            the plan (tiers, chunks, parallel width)
│   └── STATE.md           the system of record (progress, token ledger, findings, handoff)
├── scripts/
│   ├── measure.sh         optional: measure repo + detect stack
│   └── gates.sh           optional: run the detected quality gates
└── .claude/
    └── commands/
        └── clean.md       the /clean slash command for Claude Code
```

The scripts are **optional conveniences**. The agent can run the equivalent commands directly; the scripts just make measurement and gate-running reproducible for a human too.

---

## Tooling notes (verified June 2026)

These are the package's *default* recommendations. They only apply where the repo is unopinionated; an existing, working choice is always respected.

- **Python:** [Ruff](https://docs.astral.sh/ruff/) is the consolidated lint + format + import-sort tool (replaces Black, isort, Flake8, pyupgrade, …). Sequence: `ruff check --fix` then `ruff format`. Type gate defaults to **mypy** — [ty](https://astral.sh/blog/ty) is faster but still beta and not yet a full mypy replacement, so it's used only if the repo already adopts it.
- **JS/TS:** [Biome](https://biomejs.dev/) (Rust-based lint + format, 10–100× faster) is the default for unopinionated repos; an existing Prettier + ESLint setup is honored. `tsc --noEmit` is the type gate.
- **Agent efficiency:** the agent uses [ripgrep](https://github.com/BurntSushi/ripgrep) (text) and [ast-grep](https://ast-grep.github.io/) (structural) over `cat`/`sed`/`grep` to avoid token bleed — see [TOOLBELT.md](TOOLBELT.md) for the full toolbelt and install-vs-request rules.
- **Agent instructions:** [AGENTS.md](https://agents.md/) is the cross-tool standard for project instructions.

---

## License

MIT © 2026 Michael Crosato — see [LICENSE](LICENSE).
