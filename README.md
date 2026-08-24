# Performance Debugger Skills

[![skills.sh](https://skills.sh/b/andrelramos/performance-debugger-skill)](https://skills.sh/andrelramos/performance-debugger-skill)

Two portable skills for performance work, built on the same evidence-driven process. The same content works in Claude Code, Codex, and OpenCode.

| Skill | Use it when |
|---|---|
| `brainstorm-performance-problem` | Something is slow and you cannot say where, the metrics you need are missing or untrustworthy, or the investigation is stalled waiting for data |
| `diagnose-system-performance` | The degraded signal is already located and measured, and you want the root cause |

Start with the brainstorm skill when the problem is still a complaint. It hands off to the diagnostic skill once the symptom is located.

## Install with skills.sh

Install in the current project:

```bash
npx skills add andrelramos/performance-debugger-skill --skill brainstorm-performance-problem
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance
```

Install globally:

```bash
npx skills add andrelramos/performance-debugger-skill --skill brainstorm-performance-problem --global
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance --global
```

Install both if you want the handoff: the brainstorm skill reads the diagnostic skill's decision tree when both live under the same skills directory, and falls back to a compact routing table when it does not.

> **Note:** cloning or opening this repository does not make the skills available. Agents do not discover skills from this repo's `skills/` directory — Claude Code, for example, only loads skills from `~/.claude/skills/` (user), `.claude/skills/` (project), or plugins. Run one of the install commands above, then start a new session so the skills are picked up.

## What they do

Both skills follow the same chain:

`degraded metric → observed behavior → subsystem → hypothesis → possible root cause`

`diagnose-system-performance` covers nine branches: latency; CPU; memory and garbage collection; databases; connections and pools; errors and timeouts; disk and I/O; network; queues and throughput. Every branch carries a "signals that rule out" block, so a hypothesis can be refuted rather than only confirmed.

`brainstorm-performance-problem` runs a six-phase interview, one question at a time, that turns a complaint into a located symptom, ranked hypotheses, and one decisive next measurement. Missing metrics route to a fallback ladder instead of ending the thread, and every gap becomes ranked observability debt. See [Using `brainstorm-performance-problem`](#using-brainstorm-performance-problem) below.

The default behavior of both is safe: observe first, keep diagnosis separate from remediation, and request authorization before invasive profiling, load testing, or production changes.

## Using `brainstorm-performance-problem`

Start it with the complaint exactly as you received it. Vagueness is the expected input:

```text
/brainstorm-performance-problem Checkout feels slow since last week and nobody knows why.
```

### What a session looks like

The skill asks **one question at a time** and branches on your answer. It never dumps a questionnaire.

```text
Agent:  Is this happening right now with users affected, did it start after
        a specific change, or is nothing broken yet and you want it faster?
You:    Started sometime last week, still happening.

Agent:  Who notices it — end users, an internal team, a batch job, a
        downstream service, or only a monitor?
You:    Customers. Support tickets.

Agent:  Which operation do the tickets point at? If it feels like
        "everything", name the one the complaint arrived about.
You:    Checkout. POST /orders.

Agent:  What is the healthy comparison you can actually pull — same hour last
        week, a different region, or a different tenant?
You:    We only keep 7 days of metrics.
        ↳ recorded as a gap: retention too short to hold the baseline
```

Six phases run in order, each with an exit criterion:

| Phase | Central question |
|---|---|
| F0 | Active incident, regression, or preventive optimization? |
| F1 | Who is hurt, which operation, how severely? |
| F2 | When did it start, what is the baseline, what changed? |
| F3 | Which signal dominates? |
| F4 | Where is time or resource concentrated? |
| F5 | Which hypotheses compete? |

If an answer in F4 contradicts the branch picked in F3, the skill says so and goes back to F3 instead of defending the branch.

### What it will not accept

- **Adjectives.** "Slow", "heavy", "spiking" must become a number, a unit, a window, and a segment.
- **Untagged facts.** Every answer is recorded as `measured`, `estimated`, `recalled`, or `assumed`, and provenance is never merged in the summary. A number you remember is a lead, not a baseline.
- **An unrefutable hypothesis.** Each one must carry the signal that would kill it, taken from the decision tree's "signals that rule out" block.
- **A fix.** The interview stops at the decisive next measurement. Remediation is the other skill's job.

Answering "I don't know" is always allowed. It produces a recorded gap, not a stall.

### When you don't have the metric

The skill walks a ladder from cheapest to most expensive, and will not skip ahead:

| Rung | What it is | Time to first data |
|---|---|---|
| 0 | Data you already collect and have never read — proxy logs, slow query log, runtime counters, cloud defaults | minutes |
| 1 | An indirect proxy driven by the same mechanism | minutes |
| 2 | Cheap bounded sampling, with rate, duration, and dimensions stated up front | minutes to hours |
| 3 | Minimal instrumentation answering exactly one written question | one deployment |
| 4 | Controlled experiment, with abort condition and rollback defined first | hours to days |

Each rung also states what it *cannot* answer. Rung 3 is never proposed before rungs 0 and 1 are exhausted — most "we have no metrics" turns out to be an unread access log.

Metrics that exist can still fail the trust check (aggregation, resolution, retention, scope, window alignment, collection gaps). A metric that fails is treated as absent, and the ladder starts.

### What you get out of it

A dossier at `docs/performance/YYYY-MM-DD-<symptom>.md` containing framing, facts tagged by provenance, the change list, decomposition, ranked hypotheses with their refuting signals, the decisive next measurement, gaps and assumptions, and a ranked observability debt list (at most five items, each with the question it would have answered and its first step).

Its state is one of:

| State | Meaning |
|---|---|
| `in-progress` | interview still running |
| `awaiting-measurement` | blocked on collection; the dossier names the measurement and the question it answers |
| `ready-for-diagnosis` | hypotheses complete and backed by measured facts |

The dossier is written as soon as F2 completes, so an interrupted session leaves something behind. To resume days later — after the metric you were missing finally exists — point a new session at the file:

```text
/brainstorm-performance-problem Resume docs/performance/2026-08-24-checkout-slow.md, the p99 histogram is live now.
```

At `ready-for-diagnosis`, hand it off:

```text
/diagnose-system-performance Use docs/performance/2026-08-24-checkout-slow.md as input.
```

## Structure

```text
performance-debugger-skill/
├── skills/
│   ├── brainstorm-performance-problem/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── references/
│   │       ├── interview-phases.md
│   │       ├── metric-fallback.md
│   │       ├── observability-maturity.md
│   │       └── dossier-template.md
│   └── diagnose-system-performance/
│       ├── SKILL.md
│       ├── agents/openai.yaml
│       └── references/
│           ├── decision-tree.md
│           ├── investigation-method.md
│           └── response-template.md
└── scripts/
    └── install.sh
```

## Alternative installation

The bundled script remains available for explicit Claude Code, Codex, and OpenCode targets. It installs every skill in `skills/` by default.

```bash
./scripts/install.sh --list
./scripts/install.sh --target all --scope user
./scripts/install.sh --target claude --scope user
./scripts/install.sh --target all --scope user --skill brainstorm-performance-problem
```

The installation destinations are:

| Tool | User installation | Project installation |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `.opencode/skills/` |

If a skill with the same name already exists, the installer stops without changing anything. Use `--force` to move the previous version to a timestamped backup and install the new version. Use `--dry-run` to print destinations without writing.

## Project installation

```bash
./scripts/install.sh --target all --scope project --project-dir /path/to/repository
```

## Usage

Claude Code:

```text
/brainstorm-performance-problem Users say checkout got slow this week and I don't know where to look.
/diagnose-system-performance Investigate why p99 increased after the latest deployment.
```

Codex:

```text
$brainstorm-performance-problem Help me figure out what to measure — we have almost no metrics.
$diagnose-system-performance Analyze this throughput regression using the available metrics.
```

OpenCode can select a skill automatically based on context. You can also request one explicitly:

```text
Use the diagnose-system-performance skill to investigate this service's continuous memory growth.
```

## Example requests

For `brainstorm-performance-problem`:

- “The app feels slow. I don't have APM and I don't know where to start.”
- “Something regressed last sprint but I can't prove it. What should I measure?”
- “I need p99 per endpoint and nobody ever instrumented it.”
- “We collect a lot of metrics and still can't answer why this is slow.”
- “Investigation is stuck waiting on data — help me decide what data.”

For `diagnose-system-performance`:

- “p50 is normal, but p99 has tripled. Investigate.”
- “Average CPU is at 35%, but one instance has lost throughput.”
- “After the deployment, the connection pool is exhausted during peak hours.”
- “The consumer accumulates lag even though workers appear idle.”
- “RAM usage grows continuously; distinguish cache growth, a leak, and allocator behavior.”

## Updating

Edit only the sources in `skills/`, then run the installer again with `--force`. This keeps the method, the decision tree, and the interview identical across all three tools.
