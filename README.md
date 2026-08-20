# Diagnose System Performance

[![skills.sh](https://skills.sh/b/andrelramos/performance-debugger-skill)](https://skills.sh/andrelramos/performance-debugger-skill)

## Install with skills.sh

Install in the current project:

```bash
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance
```

Install globally:

```bash
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance --global
```

Portable skill for investigating bottlenecks, regressions, and performance incidents with an evidence-driven process. The same content works in Claude Code, Codex, and OpenCode.

## What it does

The skill guides the investigation through this chain:

`degraded metric → observed behavior → subsystem → hypothesis → possible root cause`

It covers nine branches: latency; CPU; memory and garbage collection; databases; connections and pools; errors and timeouts; disk and I/O; network; queues and throughput.

The default behavior is safe: observe first, keep diagnosis separate from remediation, and request authorization before invasive profiling, load testing, or production changes.

## Structure

```text
performance-diagnostics-skill/
├── skills/diagnose-system-performance/
│   ├── SKILL.md
│   ├── agents/openai.yaml
│   └── references/
│       ├── decision-tree.md
│       ├── investigation-method.md
│       └── response-template.md
└── scripts/
    └── install.sh
```

## Alternative installation

The bundled script remains available for explicit Claude Code, Codex, and OpenCode targets.

Install for all three tools:

```bash
./scripts/install.sh --target all --scope user
```

Install for only one tool:

```bash
./scripts/install.sh --target claude --scope user
./scripts/install.sh --target codex --scope user
./scripts/install.sh --target opencode --scope user
```

The installation destinations are:

| Tool | User installation | Project installation |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `.opencode/skills/` |

If a skill with the same name already exists, the installer stops without changing anything. Use `--force` to move the previous version to a timestamped backup and install the new version.

## Project installation

```bash
./scripts/install.sh --target all --scope project --project-dir /path/to/repository
```

## Usage

Claude Code:

```text
/diagnose-system-performance Investigate why p99 increased after the latest deployment.
```

Codex:

```text
$diagnose-system-performance Analyze this throughput regression using the available metrics.
```

OpenCode can select the skill automatically based on context. You can also request it explicitly:

```text
Use the diagnose-system-performance skill to investigate this service's continuous memory growth.
```

## Example requests

- “p50 is normal, but p99 has tripled. Investigate.”
- “Average CPU is at 35%, but one instance has lost throughput.”
- “After the deployment, the connection pool is exhausted during peak hours.”
- “The consumer accumulates lag even though workers appear idle.”
- “RAM usage grows continuously; distinguish cache growth, a leak, and allocator behavior.”

## Updating

Edit only the source in `skills/diagnose-system-performance/`, then run the installer again with `--force`. This keeps the method and decision tree identical across all three tools.
