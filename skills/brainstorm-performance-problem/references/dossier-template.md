# Dossier template

Write to `docs/performance/YYYY-MM-DD-<symptom>.md`. Keep sections that have content; delete the rest rather than filling them with assumptions.

The dossier is the interview's memory. Anyone reading it — including a later session — must be able to tell what was measured, what was guessed, and what question is still open.

```markdown
# <symptom in the user's words>

- **State:** in-progress | awaiting-measurement | ready-for-diagnosis
- **Mode:** active incident | regression | preventive optimization
- **Phase reached:** F0 | F1 | F2 | F3 | F4 | F5
- **Branch:** <decision-tree branch, or "undetermined">
- **Awaiting:** <measurement, and the question it answers — required when state is awaiting-measurement>
- **Updated:** <date>

## Framing

- **Impact:** who is hurt, how severely
- **Operation:** endpoint, job, query, screen
- **Environment:** where it happens and where it does not
- **Window:** start boundary, duration, ongoing or not
- **Baseline used:** which healthy period, and why it is comparable
- **Target:** SLO, budget, or goal — required in preventive mode

## Facts

Only observations. No inference. One line each, with provenance.

| Fact | Value | Window | Segment | Source | Provenance |
|---|---|---|---|---|---|
| p99 of POST /orders | 2.4 s | 14:00–15:00 | prod, all instances | ALB access log | measured |
| Same, healthy | ~180 ms | previous week, same hour | prod | recalled by team | recalled |

## Changes in the window

Deployments, flags, configuration, schema, infrastructure, dependencies, traffic, data volume. Include changes believed to be unrelated.

## Decomposition and segmentation

Where the time or resource concentrates. Universal or sparse. Which segments carry it and which do not — an unaffected segment is evidence.

## Hypotheses

For each, all six fields. Ranked.

### H1 — <one causal sentence>

- **Mechanism:**
- **Explains:** which facts above
- **Predicts:** signal that must exist if true
- **Refuted by:** signal that would kill it
- **Discriminating measurement:** what to collect, and its fallback rung
- **Confidence:** low | medium | high, justified by the provenance it rests on

## Decisive next step

One measurement. What it is, which hypotheses it separates, its cost and risk, and who must authorize it.

## Gaps and assumptions

What could not be answered, and what was assumed to keep going. Separate the two.

## Observability debt

Ranked, at most five.

| Rank | Question it would have answered | What to add | Level | Cost | First step |
|---|---|---|---|---|---|

## Handoff

When state is ready-for-diagnosis: hand this dossier to `diagnose-system-performance`, starting from the branch named above.
```

## Rules for maintaining it

- Write it as soon as F2 completes, not at the end. An interview interrupted before the first write leaves nothing behind.
- Never promote a fact between provenance levels without re-measuring it.
- When a hypothesis is refuted, keep it with the refuting evidence. A recorded dead end stops the next session from re-walking it.
- When the branch changes, record the previous branch and why it was abandoned.
- Ask before writing into a repository that is not the user's own.
