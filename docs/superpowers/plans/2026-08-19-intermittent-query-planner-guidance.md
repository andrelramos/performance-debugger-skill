# Intermittent Query Planner Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Teach the skill to investigate the planner when the same query shape becomes intermittently slow and to treat index hints only as temporary, palliative, reversible, monitored mitigations.

**Architecture:** The change is isolated in a new subsection of `4.1 Slow individual queries` in the existing decision tree. A reference retrieval scenario verifies that the agent distinguishes planning/optimization time from execution time, considers indexes and heavy columns, and limits recommendations of index hints.

**Tech Stack:** Markdown, portable skill for Claude Code, Codex, and OpenCode.

## Global Constraints

- Preserve evidence-driven investigation and separate diagnosis from correction.
- Do not conclude that excessive indexes or heavy columns are the root cause without measurement.
- Describe an index hint only as a temporary, palliative, reversible, monitored mitigation, not as the default solution.
- Do not create commits without an explicit user request.

---

### Task 1: Add and validate the intermittent planner branch

**Files:**
- Modify: `skills/diagnose-system-performance/references/decision-tree.md:132-148`

**Interfaces:**
- Consumes: the `4.1 Slow individual queries` branch and the principles defined in `skills/diagnose-system-performance/SKILL.md`.
- Produces: subsection `4.1.1 Same query shape slow only during some executions`.

- [ ] **Step 1: Run the scenario without the new guidance**

Use an agent in a clean context, without providing the new text, with this prompt:

```text
A query with the same query shape normally takes 30 ms, but some executions take 2 s. The extra time appears to occur before execution. The table has many indexes and a large vector column. Using only the current diagnose-system-performance skill, produce a short investigation and state whether you would force an index.
```

Expected result: the response does not reliably retrieve all these requirements: separate planning/optimization time from execution time; compare executions; evaluate the number and relevance of indexes; check the indexing, reading, and projection of the heavy column; and restrict an index hint to a temporary, palliative, reversible, monitored mitigation.

- [ ] **Step 2: Add the minimal guidance**

Insert after the list of causes in `4.1`:

```markdown
#### 4.1.1 Same query shape slow only during some executions

If the same query shape is intermittently slow, compare fast and slow executions with equivalent parameters, cardinality, cache, and concurrency. Separate planning/optimization time from execution time and check whether different plans were selected or replanned.

If the planner, optimizer, or equivalent component is slow:

- evaluate how many candidate indexes it considers and whether any indexes are redundant, overlapping, irrelevant to the query shape, or insufficiently selective; reduce or redesign indexes only after confirming usage, redundancy, and impact;
- check statistics, data distribution, and differences between estimates and actual cardinality;
- look for heavy columns, such as vectors, files, binary data, BLOBs, or large documents, and confirm whether they are included in an index, read with candidate rows/documents, or returned because projection is missing; keep these columns out of the critical path when they are not needed.

Some databases allow an index hint or equivalent mechanism to limit the planner's choices; MongoDB is one example. Consider this only as a temporary, palliative, reversible, monitored mitigation for the affected query shapes: reducing candidate plans may avoid slow planning/optimization, but forcing an index removes some of the database's ability to adapt to changes in data and workload. Prefer correcting the indexes, statistics, projection, and modeling that cause the instability.
```

- [ ] **Step 3: Rerun the scenario with the updated skill**

Run the same prompt in a clean context, now providing the updated skill.

Expected result: the response covers all five diagnostic points, does not recommend removing indexes without evidence, and presents an index hint only as a temporary, palliative, reversible, monitored mitigation with explicit monitoring and risk.

- [ ] **Step 4: Verify structure and diff**

Run: `git diff --check && git diff -- skills/diagnose-system-performance/references/decision-tree.md`

Expected: `git diff --check` produces no output; the diff contains only the new subsection in the `4.1` branch.
