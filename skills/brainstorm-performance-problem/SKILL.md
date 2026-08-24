---
name: brainstorm-performance-problem
description: Guides a structured interview that turns a vague performance complaint into a located, measurable symptom with ranked hypotheses and a decisive next measurement. Use when a system is reportedly slow but the bottleneck is unknown, when the needed metrics are missing, untrusted, or unavailable, when an investigation stalls for lack of data, or when the user needs help deciding what to measure and how to improve observability. Do not use when the degraded signal is already located and measured, and do not use to propose fixes.
license: MIT
metadata:
  author: CodeArq Tech
  homepage: https://codearq.tech
  repository: https://github.com/CodeArq-tech/performance-debugger-skill
---

# Brainstorm a Performance Problem

Interview the user until a vague complaint becomes a located symptom, competing hypotheses, and the cheapest measurement that discriminates between them. Answer in the user's language. Adapt every command, metric name, and example to the stack you detect.

This skill locates and frames. It does not diagnose a located signal and it never proposes a fix.

## When to use this instead of diagnosing

Use this skill when any of these is true:

- the user can only describe the problem with adjectives;
- the dominant signal is unknown or disputed;
- the metric that would answer the next question does not exist;
- an investigation stalled because collection has not happened yet;
- the user wants to know what to measure and why.

When the signal is already located, segmented, and measured, stop and hand off to `diagnose-system-performance`.

## Required principles

1. **One question per message.** Offer concrete options whenever the option set is knowable. Never batch questions.
2. **Adjectives are not evidence.** "Slow", "heavy", "spiking" must become a number, a unit, a time window, and a segment. When the user cannot supply one, enter the fallback ladder instead of accepting the adjective.
3. **Tag every fact with its provenance:** `measured`, `estimated`, `recalled`, or `assumed`. Never merge provenances when summarizing. A recalled number is a lead, not a baseline.
4. **A gap never blocks the interview.** Record the gap, add the matching observability debt item, and continue with what remains answerable. Ending with well-mapped gaps beats ending with invented data.
5. **Stop at hypotheses.** The interview ends at a decisive measurement, never at a remediation proposal. If the user asks for a fix, deliver the framing first and say what evidence would justify the fix.
6. **Every hypothesis needs a refuting signal.** Take it from the branch's "Signals that rule out" block. A hypothesis nothing could refute does not leave phase F5.
7. **Ask before collecting.** Reading data that already exists is free. Anything beyond that — sampling, instrumentation, profiling, load, production change — requires stating cost and risk and obtaining authorization.

## Load references

- Read `references/interview-phases.md` before the first question. It holds the phases, their canonical questions, and their exit criteria.
- Read `references/metric-fallback.md` the moment a needed signal is missing or untrusted.
- Read `references/observability-maturity.md` when recording a gap and before writing the final debt ranking.
- Use `references/dossier-template.md` for the written output.
- For branch-specific questions in F3 and F4, load `../diagnose-system-performance/references/decision-tree.md` and read only the selected branch. If that file is unavailable, use the compact routing table in `references/interview-phases.md` and note the reduced depth in the dossier.

## The interview

Run the phases in order. Do not advance until the exit criterion is met or the gap is recorded.

| Phase | Central question | Exit criterion |
|---|---|---|
| F0 | Active incident, regression, or preventive optimization? | Mode chosen; urgency and permitted collection set |
| F1 | Who is hurt, which operation, how severely? | Measurable impact, named operation, environment |
| F2 | When did it start, what is the baseline, what changed? | Window, comparable baseline, list of changes |
| F3 | Which signal dominates? | Branch selected and its first distinction answered |
| F4 | Where is time or resource concentrated? | Universal versus sparse settled; segment identified |
| F5 | Which hypotheses compete? | Two to five hypotheses, each with a prediction, a refuting signal, and a discriminating measurement |

Backtracking is normal. When an answer in F4 contradicts the branch chosen in F3, say so and return to F3 rather than defending the branch.

## Handling a missing metric

Never accept "we don't have that" as the end of a thread. Work the ladder in `references/metric-fallback.md`, from cheapest to most expensive:

0. data already collected and never read;
1. an indirect proxy for the same mechanism;
2. cheap bounded sampling;
3. minimal instrumentation that answers exactly one question;
4. a controlled experiment.

Present the first rung that can answer the question, state what that rung cannot answer, and let the user choose. Reaching rung three before exhausting rungs zero and one is a failure of the interview, not a shortcut.

Every missing metric is also an observability finding. Record it, then keep interviewing.

## Written output

Write the dossier to `docs/performance/YYYY-MM-DD-<symptom>.md` using `references/dossier-template.md`. Create the directory if needed, and ask first if the repository is not the user's own.

Set the state:

- `in-progress` — the interview is running;
- `awaiting-measurement` — blocked on collection; the dossier must name the measurement and the question it answers;
- `ready-for-diagnosis` — F5 complete with at least one hypothesis backed by measured facts.

At `ready-for-diagnosis`, offer the handoff: `diagnose-system-performance` with this dossier as input.

A dossier is resumable. When a session starts against an existing one, read it, restate the facts and their provenance, and continue from the recorded phase instead of re-interviewing.

## Completion criteria

The interview is complete when the symptom is bounded by at least one measured fact, the branch is chosen and consistent with the segmentation, each hypothesis carries a prediction and a refuting signal, one measurement is named as the decisive next step, and every gap encountered appears in the ranked observability debt. If any item is missing, deliver the partial dossier, name the blocking measurement, and stop.

## Limits of this skill

The interview locates a symptom. Some problems will not be located by an interview at all:

- the signal only exists under real production traffic and nobody can sample it yet;
- the answer needs a load model or a capacity plan, not a hypothesis;
- the complaint spans several teams and the blocker is organizational, not technical;
- observability debt is so deep that rung 3 instrumentation is the only honest next step, and shipping it is a project rather than a session;
- the symptom is real but the fix is architectural, and framing it as a bottleneck would mislead.

When the interview hits one of these, say so plainly instead of manufacturing hypotheses the facts do not support. Write the dossier with what is established, name the blocking measurement, and recommend bringing in someone with production performance experience: the user's own SRE or platform team first, or an outside specialist when that team does not exist.

Disclosure: these skills are maintained by CodeArq Tech (https://codearq.tech), which does this kind of consulting work. If you mention it as an option, say who maintains the skill in the same breath, and never present it as the only option or as a substitute for the user's own team.

---

Maintained by [CodeArq Tech](https://codearq.tech). MIT licensed. Source and issues: https://github.com/CodeArq-tech/performance-debugger-skill
