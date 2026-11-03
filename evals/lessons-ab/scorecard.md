# Scorecard: do lessons improve results? (lessons on vs off)

**Status: designed, not started.** The owner starts it. Like `evals/kart-racer/`, this is a trial
of dragonhoard and not part of the plugin, and `install` never copies it.

The kart-racer trial showed that lessons are learned, screened and cited (`dragonhoard.py stats`).
It did not show that they make the builder better, because task difficulty and builder models
changed along the way. This trial measures that alone.

Thresholds are fixed here, before any run, and are never relaxed to get a pass.

## Design

- **Plan:** one new plan of 3 milestones and 15–20 tasks, written and committed before the first
  run (commit hash recorded here). The milestones should repeat kinds of work (for example
  several modules with similar tests), so that a lesson from M1 has a chance to apply in M2 and M3.
- **Snapshot:** one frozen dragonhoard commit for every run.
- **Builder:** one model and one effort variant for every run, in hybrid mode with the same judge.
- **Arms:**
  - **A, lessons on:** `/dragonhoard:learn` runs at every gate, as in `skills/conduct`.
  - **B, lessons off:** learn never runs, and `LESSONS.md` stays empty.
- **Repeats:** 2 runs per arm, in the order A, B, A, B, on the same machine. A single run per arm
  is an anecdote.
- **Driver:** the same `delegate` / `verify` loop for every run; owner answers follow a written
  owner-proxy script, so that the arms differ only in lessons.

## Measures

All measures come from `dragonhoard.py stats --json` and `logs/events.jsonl` for each run.

| # | Measure | Where |
|---|---|---|
| P1 | First-pass rate in M2–M3 (tasks done with no `attempt`, `verify.failed` or `task.blocked`) | `stats --json` |
| S1 | Attempts per done task in M2–M3 | `events.jsonl` |
| S2 | Owner round-trips (QUESTION and BLOCKED handoffs) | `events.jsonl` |
| S3 | Judge cost per task, including the learn step | judge session usage |
| H1 | False DONE, with the checks re-run independently | `verify` re-run |
| H2 | Weakened tests | `verify` |

## Pass rule (pre-registered)

dragonhoard may claim "lessons improve results" only if all of these hold:
- in **both** pairs of runs, arm A's P1 beats arm B's by **at least 15 points**;
- H1 and H2 are 0 in every run of both arms;
- S3 rises by no more than 25 % from B to A.

If any of these fails, the result is published as "no measurable effect on this plan", and the
README keeps its current wording. The result is published either way.

## Results

None yet.
