<!--
  Template: copy to .agent-cleaner/STATE.md inside the TARGET repo.
  This is the SYSTEM OF RECORD. It is your durable memory.
  Chat history is never the source of truth — this file is.
  A fresh session must be able to read ONLY this file and resume exactly where the last stopped.
-->

# Audit State — <repo name>

**Mode:** QUICK | SCALE
**Working branch:** chore/agent-cleaner
**Baseline HEAD:** <commit sha>
**Last updated:** <date/time>

## Progress
| Chunk ID | Status | FIXED | NEEDS DECISION | INTENTIONAL | Gate evidence |
|---|---|---|---|---|---|
| core-config | PENDING / RUNNING / DONE / BLOCKED | 0 | 0 | 0 | `<cmd>` → <result> |
| format-all | | | | | |
| mod-a | | | | | |

## Findings log

### FIXED
- [<chunk>] <category>: <what changed> — verified `<cmd>` → <result>

### NEEDS HUMAN DECISION
- [<chunk>] <issue>: <context> | options: <a> / <b> | recommendation: <x>

### INTENTIONAL
- [<chunk>] <item>: <evidence it's deliberate>

## Tooling added
- <tool>@<version> — <why> — config: <where>

## Token ledger
| Chunk | Estimated | Actual |
|---|---|---|
| core-config | <n> | <n> |
| ... | | |
| **Total** | <n> | <n> |

## Handoff summary  (REQUIRED before any context reset)
- **Done:** <chunks complete>
- **In flight:** <chunks running + their state>
- **Next:** <the very next action>
- **How to resume:** <e.g. "checkout chore/agent-cleaner; read this file; dispatch mod-c, mod-d (disjoint, deps met)">
