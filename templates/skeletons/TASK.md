# M<n>-T<nn> — <title>

<!-- Copy into {{root}}/M<n>-<name>/tasks/. The relative links resolve from there. -->

| Field | Value |
|---|---|
| Status | TODO |
| Depends on | <task IDs / gate> |
| Milestone constitution | [../CONSTITUTION.md](../CONSTITUTION.md) (inherits [global](../../CONSTITUTION.md)) |
| Plan source | <plan file> §<section> |
| Journal | `tasks/M<n>-T<nn>-<slug>.journal.md` (create on first attempt) |

## 0. Context to load

Load these and nothing else:
- `{{root}}/CONSTITUTION.md`, `{{root}}/DIGEST.md`, `{{root}}/LESSONS.md`
- `{{root}}/M<n>-<name>/CONSTITUTION.md`
- this pack
- <source files, read-only unless listed under Files>
- <existing tests that show the house style>

Excerpts from the plan the task depends on, copied here so the plan need not be opened:

> <excerpt> (plan §x.y)

## 1. Plan

- **Goal:** <one sentence, observable>
- **In scope:** <bullets>
- **Out of scope:** <bullets; later tasks own these>
- **Files:** <1–3 implementation files> + `<one focused test file>`
- **Consumes:** <existing functions/classes with path:line>
- **Produces:** <new public names and signatures>
- **Open options:** <choices to explore before building, or "none">
- **Do not:** <specific traps>

## 2. Explore (only if Open options is not "none")

- [ ] Facts retrieved (scouts), with file:line evidence.
- [ ] ≤ 3 options spiked in isolation; each report has the command run and its result.
- [ ] Owner's pick recorded: `dragonhoard.py log <task> option.chosen "<choice>: <why>"`.

## 3. Verify (before building)

- [ ] Each consumed interface exists with the stated signature (`grep -n`, paste into journal).
- [ ] The standard checks are green before any change. Record the counts.
- [ ] The focused tests are written first, run, and fail for the expected reason.
- [ ] <task-specific preconditions>

On any mismatch, record `BLOCKED` with evidence and stop.

## 4. Build

1. <ordered, bounded steps>

## 5. Test

{{checks}}

Acceptance (tick each, with evidence):
- [ ] <observable criterion>

## 6. Record and hand off

- [ ] Journal entry written, every attempt recorded.
- [ ] Milestone `PROGRESS.md` row and `STATUS.md` row updated with real output.
- [ ] `dragonhoard.py log <task> task.done "<one line>"` (or `task.blocked "<reason>"`).
- [ ] `dragonhoard.py digest` and `dragonhoard.py check` → PASS.
- **BLOCKED if:** <task-specific triggers>
- **Next:** <task ID>
