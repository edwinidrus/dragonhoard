# Global constitution

Binding on every milestone and every task. A milestone constitution may add articles; it may
never relax one here. If a task seems to require breaking an article, stop and report `BLOCKED`.
The owner decides; the coding agent does not. Add project-specific articles below section VI.

## I. Honest outcomes

1. **Real output only.** `PROGRESS.md`, gate logs and journals record the command actually run
   and its actual result. Never paraphrase a failure into a pass.
2. **Failure states stay distinct.** `BLOCKED` is not `FAILED`; partial work is preserved.
3. **Unknown stays unknown.** Do not invent upstream facts: APIs, versions, behaviour, results.
   Pin and record what was observed.

## II. Verification integrity

4. **Never weaken a test to make it pass.** No weakened assertion, skipped test, regenerated
   expected answer or relaxed validator.
5. **Test first.** The focused test is written before the build and fails for the expected
   reason.
6. **Fixtures are labelled.** Fake or mocked output is never evidence that a live integration
   passed. A blocked live check stays blocked.

## III. Scope

7. **One task per session.** 1–3 implementation files plus one focused test file. Split a task
   rather than exceed this. Never build a later milestone's feature early.
8. **The pack is the contract.** Stay inside its file list. If the pack is wrong, stop and
   report; do not silently widen scope.

## IV. Exploration

9. **Bounded.** At most 3 options per open choice, each spike timeboxed and isolated.
10. **The owner picks.** Agents present evidence; the owner chooses; the choice and its evidence
    are recorded as an `option.chosen` event and in the journal. A recorded choice is not
    re-litigated without new evidence.

## V. Memory

11. **Append-only.** Journals, `logs/events.jsonl` and `logs/lessons.jsonl` are never edited or
    truncated. Corrections are new entries.
12. **Generated files are not canonical.** `DIGEST.md` and `LESSONS.md` are rebuilt from the
    logs; never edit them by hand.

## VI. Learning: learn between tasks, act frozen

13. **A task never changes the lessons it uses.** Lessons are proposed after a task, not during.
14. **The only path to a lesson is gated:** propose with provenance → deterministic screen →
    frontier-model judge → **owner approval**. Nothing is auto-approved. A judge may add a
    warning; it can never clear a screen failure.
15. **Lessons are procedural.** They say *how* to work, never secrets, URLs or absolute paths.
16. **Revocable.** Any lesson can be revoked; it then leaves `LESSONS.md` and the digest.

## VII. Secrets

17. **Never print, log, commit or paste a secret value**, including in journals, `PROGRESS.md`,
    events and lessons.
