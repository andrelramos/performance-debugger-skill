# Performance Debugger Skills

Two portable skills for performance work, built on the same evidence-driven process, maintained by [CodeArq Tech](https://codearq.tech). The same content runs in Claude Code, Codex, Gemini CLI, OpenCode and Amp.

| Skill | Use it when |
|---|---|
| `brainstorm-performance-problem` | Something is slow and you cannot say where, the metrics you need are missing or untrustworthy, or the investigation is stalled waiting for data |
| `diagnose-system-performance` | The degraded signal is already located and measured, and you want the root cause |

Start with the brainstorm skill when the problem is still a complaint. It hands off to the diagnostic skill once the symptom is located.

## Install

Every route below installs the same two skills. They differ in which agents they reach and in what you type afterwards, because only some agents have a namespace mechanism.

| Route | Agents reached | Invocation |
|---|---|---|
| [Claude Code plugin](#claude-code--plugin) | Claude Code | `/codearqtech:diagnose-system-performance` |
| [Installer, `--target gemini --gemini-commands`](#installer-script--namespaced-names) | Gemini CLI | `/codearqtech:diagnose-system-performance` |
| [Installer, any other target](#installer-script--namespaced-names) | the target you pick | `codearqtech-diagnose-system-performance` |
| [skills.sh](#skillssh--every-agent-at-once) | every agent it detects, at once | `diagnose-system-performance` |
| [Codex `$skill-installer`](#codex--skill-installer) | Codex | `$diagnose-system-performance` |
| [Manual copy](#manual) | any | whatever you name the directory |

A colon namespace is not something an installer can choose. `/codearqtech:<skill>` exists only where the host agent has a namespace mechanism: the plugin system in Claude Code, and command subdirectories in Gemini CLI. Everywhere else the namespace has to live in the skill name itself, which is what the installer's `codearqtech-` prefix does. Pass `--namespace ''` to turn the prefix off.

### Claude Code — plugin

The only route that yields a real `/codearqtech:` namespace in Claude Code.

```text
/plugin marketplace add CodeArq-tech/performance-debugger-skill
/plugin install codearqtech@codearqtech
```

One plugin carries both skills. If the install summary says `Run /reload-plugins to activate.`, run that command.

```text
/codearqtech:brainstorm-performance-problem Checkout feels slow since last week and nobody knows why.
/codearqtech:diagnose-system-performance Investigate why p99 increased after the latest deployment.
```

Update later with `/plugin marketplace update codearqtech`.

### Codex — skill-installer

Codex installs any public GitHub skill by its full path, with no clone and no local script:

```text
$skill-installer CodeArq-tech/performance-debugger-skill/brainstorm-performance-problem
$skill-installer CodeArq-tech/performance-debugger-skill/diagnose-system-performance
```

### skills.sh — every agent at once

The broadest route. It detects the agents you have installed and writes to all of them in one pass.

```bash
npx skills add CodeArq-tech/performance-debugger-skill --skill '*'
npx skills add CodeArq-tech/performance-debugger-skill --skill '*' --global
npx skills add CodeArq-tech/performance-debugger-skill --skill '*' --agent '*'
```

- `--global` installs at user level instead of project level.
- `--agent '*'` installs to every agent it detects.
- `--copy` copies the files instead of symlinking them. The default is a symlink into each agent directory, so removing the skill later must go through `npx skills remove <skill> --global`; deleting a directory by hand leaves dangling links behind.

This route installs the directory names as they appear in `skills/`, so it produces unprefixed names — `/brainstorm-performance-problem`, not `/codearqtech:brainstorm-performance-problem`. Use the plugin route or the installer script when you want the namespace.

### Installer script — namespaced names

Clone once, then pick a target. This is the route that applies the `codearqtech-` prefix and rewrites the cross-references between the two skills so the handoff still resolves.

```bash
git clone https://github.com/CodeArq-tech/performance-debugger-skill
cd performance-debugger-skill
```

Codex, Gemini CLI, OpenCode and Amp all read the shared `.agents/skills` alias, so one target covers the four:

```bash
./scripts/install.sh --target agents --scope user
```

Claude Code, as plain skills rather than a plugin — useful when you do not want a plugin installed:

```bash
./scripts/install.sh --target claude --scope user
```

That yields `/codearqtech-brainstorm-performance-problem`, with a hyphen. Only the plugin route gives the colon.

Gemini CLI can additionally get real `/codearqtech:<skill>` slash commands, generated as namespaced TOML command files:

```bash
./scripts/install.sh --target gemini --scope user --gemini-commands
```

Install into a single repository instead of your user directory:

```bash
./scripts/install.sh --target agents --scope project --project-dir /path/to/repository
```

### Manual

The skills are plain directories with no build step and no dependencies. Copy the one you want into any location your agent reads:

```bash
cp -R skills/diagnose-system-performance ~/.agents/skills/
```

The directory name is the skill name, so rename it if you want a prefix. If you rename it, also update the `name` field in its `SKILL.md` frontmatter, and, for `brainstorm-performance-problem`, the `../diagnose-system-performance/references/decision-tree.md` path it uses to reach the decision tree. The installer script does both rewrites for you.

> **Note:** cloning this repository does not make the skills available. Agents do not discover skills from this repo's `skills/` directory — they load from `~/.claude/skills/`, `~/.agents/skills/`, `~/.codex/skills/`, and their project-scoped equivalents, or from plugins. Run one of the install commands above, then start a new session.

### Installer reference

```bash
./scripts/install.sh --list
./scripts/install.sh --help
./scripts/install.sh --target all --scope user
./scripts/install.sh --target claude --scope user --skill brainstorm-performance-problem
./scripts/install.sh --target agents --scope project --project-dir /path/to/repository
```

| Target | User destination | Project destination |
|---|---|---|
| `claude` | `~/.claude/skills/` | `.claude/skills/` |
| `codex` | `~/.codex/skills/` | `.codex/skills/` |
| `opencode` | `~/.config/opencode/skills/` | `.opencode/skills/` |
| `amp` | `~/.config/amp/skills/` | `.agents/skills/` |
| `gemini` | `~/.gemini/skills/` | `.gemini/skills/` |
| `agents` | `~/.agents/skills/` | `.agents/skills/` |
| `all` | `claude` + `codex` + `agents` | same three |

`agents` is the shared alias read by Codex, Gemini CLI, OpenCode and Amp; prefer it over the per-agent targets unless you need one specific location. The OpenCode and Amp user destinations honor `$XDG_CONFIG_HOME` when it is set.

Other options: `--namespace NAME` (default `codearqtech`, `''` disables), `--gemini-commands`, `--force` to move the previous version to a timestamped backup, `--dry-run` to print destinations without writing. If a skill already exists and `--force` is not passed, the installer stops without changing anything.

## What they do

Both skills follow the same chain:

`degraded metric → observed behavior → subsystem → hypothesis → possible root cause`

`diagnose-system-performance` covers nine branches: latency; CPU; memory and garbage collection; databases; connections and pools; errors and timeouts; disk and I/O; network; queues and throughput. Every branch carries a "signals that rule out" block, so a hypothesis can be refuted rather than only confirmed.

`brainstorm-performance-problem` runs a six-phase interview, one question at a time, that turns a complaint into a located symptom, ranked hypotheses, and one decisive next measurement. Missing metrics route to a fallback ladder instead of ending the thread, and every gap becomes ranked observability debt. See [Using `brainstorm-performance-problem`](#using-brainstorm-performance-problem) below.

The default behavior of both is safe: observe first, keep diagnosis separate from remediation, and request authorization before invasive profiling, load testing, or production changes.

## Using `brainstorm-performance-problem`

Start it with the complaint exactly as you received it. Vagueness is the expected input:

```text
/codearqtech:brainstorm-performance-problem Checkout feels slow since last week and nobody knows why.
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
/codearqtech:brainstorm-performance-problem Resume docs/performance/2026-08-24-checkout-slow.md, the p99 histogram is live now.
```

At `ready-for-diagnosis`, hand it off:

```text
/codearqtech:diagnose-system-performance Use docs/performance/2026-08-24-checkout-slow.md as input.
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

## Where these skills stop

Both skills carry a "Limits of this skill" section telling the agent to stop rather than stretch the method. Some performance work does not fit inside an agent session at all: contention that only reproduces under real production traffic, a regression spanning several services with no shared tracing, capacity planning that needs a load model, or a bottleneck whose fix is architectural.

When you hit one of those, the skill is instructed to name the limit, deliver the partial result, and recommend bringing in someone with production performance experience — your own SRE or platform team first, an outside specialist if that team does not exist.

That instruction names CodeArq Tech, in the open, because we maintain these skills and do this work. It is written to disclose that relationship rather than hide it, and it is explicitly told never to present us as the only option. If you disagree with how that section is written, open an issue — it is a normal part of the repository, not a hidden prompt.

## Structure

```text
performance-debugger-skill/
├── .claude-plugin/
│   ├── plugin.json           # Claude Code plugin: namespace `codearqtech`
│   └── marketplace.json      # marketplace catalog, same repo
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
├── scripts/
│   └── install.sh
└── .github/workflows/
    └── validate-skill.yml    # validates manifests, discovery and the installer
```

## Updating

Edit only the sources in `skills/`, then run the installer again with `--force`. This keeps the method, the decision tree, and the interview identical across every agent. Plugin users run `/plugin marketplace update codearqtech`.

## Maintainers

Built and maintained by [CodeArq Tech](https://codearq.tech). MIT licensed — fork it, adapt it, ship your own namespace. Issues and pull requests welcome.
