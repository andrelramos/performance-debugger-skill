# Brainstorm Performance Problem Design

## Objective

Add a second skill that turns a vague performance complaint into a located, measurable symptom through a guided interview. The existing `diagnose-system-performance` skill assumes the user already knows which signal degraded and can produce numbers. This skill serves the case before that: the user knows something is slow, cannot say where, and may not have the metric that would answer the question.

The interview ends at ranked hypotheses and a decisive next measurement. It never proposes a fix.

## Scope

Add `skills/brainstorm-performance-problem/` with `SKILL.md`, `agents/openai.yaml`, and four references. Update the installer to handle multiple skills, the CI workflow to expect two skills, and the README to document both. Do not change any existing diagnostic guidance.

## Relationship to the Existing Skill

The two skills are siblings, not layers. `brainstorm-performance-problem` locates and frames; `diagnose-system-performance` investigates a located signal. The brainstorm skill hands off by writing a dossier the diagnostic skill can read as input.

Branch-specific questions load `../diagnose-system-performance/references/decision-tree.md`, which resolves when both skills are installed under the same skills root. The decision tree is not duplicated. When the sibling file is absent, `references/interview-phases.md` carries a compact routing table sufficient to reach a branch and name what is missing.

## Interview Protocol

Six phases run in order. Each has an exit criterion. The interview does not advance until the criterion is met or the gap is explicitly recorded as observability debt.

| Phase | Central question | Exit criterion |
|---|---|---|
| F0 | Is this an active incident, a regression, or preventive optimization? | Mode chosen; it sets urgency and what collection is permitted |
| F1 | Who is hurt, which operation, how severely? | Measurable impact, named operation, environment |
| F2 | When did it start, what is the baseline, what changed? | Window, comparable baseline, list of changes |
| F3 | Which signal dominates? | Decision-tree branch selected and its first distinction answered |
| F4 | Where is time or resource concentrated? | Universal versus sparse established; segment identified |
| F5 | Which hypotheses compete? | Two to five hypotheses, each with a prediction, a refuting signal, and the cheapest discriminating measurement |

## Protocol Rules

1. One question per message, multiple choice whenever the option set is knowable.
2. Adjectives are not evidence. "Slow" must become a number, a unit, a window, and a segment. When the user cannot supply one, enter the fallback ladder.
3. Every answer is recorded with its provenance: measured, estimated, recalled, or assumed. Provenance is never mixed in the synthesis.
4. A gap never blocks the interview. Record the gap, add the corresponding observability debt item, and continue with what remains answerable.
5. The interview stops at hypotheses. It does not propose remediation.
6. Every hypothesis must carry a refuting signal, drawn from the branch's "Signals that rule out" block. A hypothesis without one does not leave F5.
7. Collection beyond reading existing data requires the user's authorization, with cost and risk stated first.

## Metric Fallback Ladder

When a needed signal does not exist, `references/metric-fallback.md` walks rungs in increasing cost and risk: data already collected and unread; indirect proxy; cheap sampling; minimal instrumentation answering exactly one question; controlled experiment. Each rung declares what it answers, what it cannot answer, its cost, its risk, and its time to first data. Rung three is not reached before rungs zero and one are exhausted.

The ladder is described by concept, not by stack. The agent detects the user's actual stack from the repository and the interview, then translates the chosen rung into a concrete command or code change at that moment.

## Observability Coaching

`references/observability-maturity.md` defines levels zero through five and maps each recorded gap to the level that would have closed it. Prioritization is not "advance a level": it ranks by how many questions in this specific investigation the missing signal would have answered, divided by its cost. The reference also teaches the reasoning that keeps people stuck: a signal exists to answer a question, cardinality determines whether it survives, and retention determines how far back a baseline can be compared.

## Dossier

The interview writes `docs/performance/YYYY-MM-DD-<symptom>.md` from `references/dossier-template.md`, with state `in-progress`, `awaiting-measurement`, or `ready-for-diagnosis`. Facts are grouped by provenance. The final section is the ranked observability debt. When the state reaches `ready-for-diagnosis`, the skill offers the handoff to `diagnose-system-performance` with the dossier as input.

An interview that stalls waiting for collection is resumable: the dossier records the phase reached, the measurement awaited, and the question that measurement answers.

## Repository Plumbing

`scripts/install.sh` currently hardcodes a single skill name. It must iterate every subdirectory of `skills/` containing a `SKILL.md`, and accept `--skill NAME` to install one. Backup, force, and dry-run behavior stay unchanged, and preflight must check every selected skill before writing anything.

`.github/workflows/validate-skill.yml` asserts `Found 1 skill`. It must assert two and grep both names.

`README.md` gains the skills.sh install command for the new skill, an updated structure block, and a short statement of which skill to reach for when.

## Acceptance Criteria

- The skills CLI discovers exactly two skills: `diagnose-system-performance` and `brainstorm-performance-problem`.
- The new `SKILL.md` has valid frontmatter with a matching directory name, `license: MIT`, and string metadata, consistent with the existing skill.
- The interview cannot reach F5 output without either measured facts or explicitly recorded gaps for every unanswered exit criterion.
- Every hypothesis produced carries a prediction, a refuting signal, and a discriminating measurement.
- A missing metric produces a ranked fallback path rather than a stalled interview.
- The installer installs both skills by default and one with `--skill`, and `sh -n scripts/install.sh` passes.
- No existing diagnostic guidance or runtime behavior changes.
