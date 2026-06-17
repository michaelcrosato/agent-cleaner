<!--
  Template: copy to .agent-cleaner/PLAN.md inside the TARGET repo, then fill in.
  This is the plan. The live system of record is STATE.md.
-->

# Audit Plan — <repo name>

**Mode:** QUICK | SCALE
**Generated:** <date>
**Working branch:** chore/agent-cleaner
**Baseline HEAD:** <commit sha>

## Repo summary
- Files / dirs: <n> / <n>
- Total LOC: <n>
- Largest files: <list>
- Stack(s): <python | node | go | rust | …>
- Canonical commands (from CI / Makefile / package scripts):
  - install: `<cmd>`
  - lint:    `<cmd>`
  - format:  `<cmd>`
  - types:   `<cmd>`
  - test:    `<cmd>`

## Tooling  (see TOOLBELT.md)

**Gates** — required; installed as **repo dev-deps**, pinned:
| Tool | Status | Notes |
|---|---|---|
| ruff | detected / installed / n/a | |
| mypy | detected / installed / n/a | |
| pytest | detected / installed / n/a | |
| biome \| prettier+eslint+tsc | detected / installed / n/a | js/ts |

**Accelerants** — optional; **agent environment**, never committed:
| Tool | Available? | Action |
|---|---|---|
| ripgrep (rg) | yes / no | use / install / request |
| ast-grep | yes / no | use / install / request |
| tokei | yes / no | use / install / request |

> Gates are pinned and recorded here so the environment is reproducible.
> Accelerants live in the agent environment only.

## Tier / DAG plan
| Tier | Chunk ID | Scope (paths) | Depends on | Parallel group | Write-surface notes |
|---|---|---|---|---|---|
| 1 | core-config | <paths> | — | — | global config / types |
| 2 | format-all | (whole repo) | core-config | — | one mechanical pass before fan-out |
| 3 | mod-a | <paths> | format-all | P1 | disjoint from mod-b |
| 3 | mod-b | <paths> | format-all | P1 | disjoint from mod-a |
| 4 | docs | <paths> | mod-* | P2 | |
| 5 | integration | (whole repo) | all | — | global gates + report |

**Max parallel width:** <n>  (Tier-3 chunks with satisfied deps and disjoint write-surfaces)

## Token estimate
- Rough total: <n>  (refined against actuals in STATE.md as the run proceeds)
