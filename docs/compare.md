# dragonhoard compared with other planning tools

As of 2026-11-03. The other tools change quickly. Star counts are approximate, taken from public
pages and articles, and the descriptions summarise the tools' own docs. Corrections are welcome.

## At a glance

| | **dragonhoard** | **Superpowers** | **Spec Kit** | **BMAD-METHOD** | **GSD** | **Compound Engineering** | **Ralph loop** |
|---|---|---|---|---|---|---|---|
| Core idea | Plan → milestones → task packs; one task per session through plan → explore → verify → build → test → record | Discipline skills (brainstorm, plan, TDD, debug, verify) loaded on demand | Spec-driven: constitution → spec → plan → tasks, committed to git | Agile persona team (analyst, PM, architect, dev, QA) | Meta-prompting and context engineering, spec-driven | Plan → work → review → compound | The same prompt rerun until no work is left |
| Context per task | One self-contained pack | Plan doc in the conversation | Grows with the spec artifacts | Many persona docs | Fresh subagent context per plan | CLAUDE.md and docs | The whole repo on every loop |
| Who owns the state | A deterministic stdlib CLI (STATUS, `events.jsonl`, digest) | The model, through prompt wording | Templates and a CLI | The model, through docs | The model, through docs | The model, through docs | git commits |
| Checking "done" | `verify` re-runs the checks independently, diffs scope against the pack, and catches weakened tests | A verification skill (prompt-enforced) | `/analyze` and checklists | A QA persona | A verify step | Review agents | Tests inside the loop |
| Memory across sessions | Append-only logs and a 150-line digest, printed at session start | Plan files | Spec files | Docs | State files | Docs | git history |
| Learns over time | **Yes, gated**: deterministic screen, frontier judge, human approval, provenance, revoke | No lesson loop in the core skills | No | No | No | Yes, **ungated**: the agent writes its learnings into docs | No |
| Cheap builder, frontier judge | Yes (hybrid mode: OpenCode builds, Claude Code judges) | No | No | No | No | No | No |
| Hosts | Claude Code, OpenCode, Codex CLI, Cline, any `AGENTS.md` agent | Claude Code, Codex and others | 30+ agents | Many | Claude Code | Claude Code, Codex, Cursor | Any |
| Public evidence | A pre-registered 96-task trial with its failures published | Wide adoption and user reports | Tutorials | Tutorials | Articles | Every's essays | User reports |
| Adoption | New | ~200k★, official marketplace | ~90–100k★ | ~55k★ | ~64k★, archived June 2026 | ~26k★ | A pattern, not a product |

## Where dragonhoard is strong

- **Learning you can audit.** Every lesson passes a deterministic screen, a frontier-model judge
  and your approval. Each one keeps its provenance (`M4-T02#1`) and can be revoked. In the trial
  the screen rejected an injected "ignore previous instructions" lesson.
- **Lessons work across models.** Most lessons were approved while Claude built. In the hybrid
  phase the cheaper OpenCode builder cited one in 40 of its 82 journals.
- **State that cannot drift.** Task selection, logs, the digest, the lessons file and the checks
  are code, not prompt wording.
- **An honest "done".** No false DONE in 96 independently audited tasks.
- **Cost.** In hybrid mode, Claude's spend fell from about $9.8 to about $1.5 per task, and the
  builder used $4.60 of paid tokens for the whole trial.

## Where dragonhoard is weaker

- **Ceremony.** One task per session, plus your sign-off on lessons and gates, is slow for a quick
  fix. For a one-line change, use a lighter tool or none.
- **Unproven effect size.** `stats` shows that lessons exist and are cited. It does not yet show
  that they raise the first-pass rate. The A/B trial that would measure it is designed in
  [evals/lessons-ab](../evals/lessons-ab/scorecard.md) but has not run.
- **Shaping quality.** Packs can carry stale interfaces. The builder stops with evidence instead of
  guessing, but every stop costs a round-trip with you.
- **Small community.** It has fewer skills and fewer users than Superpowers or Spec Kit.

## Using them together

dragonhoard does not replace discipline skills. In the trial, the OpenCode builder ran with the
Superpowers TDD, debugging and verification skills inside dragonhoard's loop. dragonhoard owns the
plan, the state, the verification and the lessons; the discipline skills shape how each step is
done.

## Sources

- Superpowers: [obra/superpowers](https://github.com/obra/superpowers)
- Spec Kit: [github/spec-kit](https://github.com/github/spec-kit); [spec-kit vs superpowers](https://martianlee.github.io/posts/2026-06-01-spec-kit-vs-superpowers)
- BMAD-METHOD: [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- GSD: [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)
- Compound Engineering: [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin)
- Workflow plugin comparison, including the Ralph loop: [chenguangliang.com](https://chenguangliang.com/en/posts/claude-code-workflow-plugins-comparison/)
- Spec-driven overview: [DataCamp tutorial](https://www.datacamp.com/tutorial/spec-driven-development-with-claude-code)
- Self-improvement through context: [ACE, arXiv:2510.04618](https://arxiv.org/abs/2510.04618)
