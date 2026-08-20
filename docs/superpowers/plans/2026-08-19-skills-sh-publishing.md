# skills.sh Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository publicly installable and continuously validated through the skills CLI and skills.sh.

**Architecture:** Preserve the canonical skill under `skills/diagnose-system-performance/`, add public license and author metadata, document skills.sh as the primary installation path, and validate discovery in GitHub Actions. Keep the existing custom installer as an alternative and do not change diagnostic behavior.

**Tech Stack:** Agent Skills `SKILL.md`, Markdown, POSIX shell, GitHub Actions, Node.js 22, `skills@1.5.23` CLI.

## Global Constraints

- Keep the canonical skill at `skills/diagnose-system-performance/`.
- Use MIT licensing and `metadata.author: andrelramos`.
- Do not add runtime compatibility restrictions.
- Preserve the existing custom installer and diagnostic guidance.
- Validation must not install into an agent directory or modify repository files.
- Do not create commits unless the user explicitly requests one.

---

### Task 1: Add public metadata and skills.sh installation documentation

**Files:**
- Create: `LICENSE`
- Modify: `skills/diagnose-system-performance/SKILL.md:1-6`
- Modify: `README.md:1-56`

**Interfaces:**
- Consumes: repository identity `andrelramos/performance-debugger-skill` and skill name `diagnose-system-performance`.
- Produces: valid public Agent Skills metadata and documented project/global skills CLI commands.

- [ ] **Step 1: Run the publishing-contract check before implementation**

Run:

```bash
test -f LICENSE && \
rg -q '^license: MIT$' skills/diagnose-system-performance/SKILL.md && \
rg -q '^  author: andrelramos$' skills/diagnose-system-performance/SKILL.md && \
rg -q 'skills.sh/b/andrelramos/performance-debugger-skill' README.md && \
rg -q 'npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance' README.md
```

Expected: FAIL because `LICENSE` and the public publishing metadata do not exist.

- [ ] **Step 2: Add the MIT license**

Create `LICENSE` with:

```text
MIT License

Copyright (c) 2026 Andre Ramos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Add Agent Skills metadata**

Change the `SKILL.md` frontmatter to:

```yaml
---
name: diagnose-system-performance
description: Diagnoses system performance bottlenecks, regressions, and incidents with an evidence-driven decision tree covering latency, CPU, memory, garbage collection, databases, connections, errors, disk, network, and queues. Use when systems are slow, throughput is low, resources are saturated or consumed abnormally, timeouts occur, performance degrades after a deployment, or a root cause must be investigated. Do not use to justify optimizations without metrics or to run destructive load tests without authorization.
license: MIT
metadata:
  author: andrelramos
---
```

- [ ] **Step 4: Add skills.sh badge and primary install commands**

Insert after the README title:

````markdown
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
````

Rename `## User installation` to `## Alternative installation` and state that the bundled script remains available for explicit Claude Code, Codex, and OpenCode targets.

- [ ] **Step 5: Run the publishing-contract check after implementation**

Run the command from Step 1 again.

Expected: PASS with exit code 0 and no output.

---

### Task 2: Add automated discovery validation

**Files:**
- Create: `.github/workflows/validate-skill.yml`

**Interfaces:**
- Consumes: the skill metadata and repository layout produced by Task 1.
- Produces: CI validation for exactly one discoverable skill and valid installer syntax.

- [ ] **Step 1: Run the CI-contract check before implementation**

Run:

```bash
test -f .github/workflows/validate-skill.yml && \
rg -q 'actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09' .github/workflows/validate-skill.yml && \
rg -q 'persist-credentials: false' .github/workflows/validate-skill.yml && \
rg -q 'actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444' .github/workflows/validate-skill.yml && \
rg -q 'npx --yes skills@1\.5\.23 add \. --list' .github/workflows/validate-skill.yml && \
rg -Fq "perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' /tmp/skills-list.txt > /tmp/skills-list-plain.txt" .github/workflows/validate-skill.yml && \
rg -Fq 'grep -q "Found 1 skill" /tmp/skills-list-plain.txt' .github/workflows/validate-skill.yml && \
rg -Fq 'grep -q "diagnose-system-performance" /tmp/skills-list-plain.txt' .github/workflows/validate-skill.yml && \
rg -q 'sh -n scripts/install.sh' .github/workflows/validate-skill.yml
```

Expected: FAIL because the workflow does not exist.

- [ ] **Step 2: Add the validation workflow**

Create `.github/workflows/validate-skill.yml` with:

```yaml
name: Validate skill

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09
        with:
          persist-credentials: false
      - uses: actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444
        with:
          node-version: 22
      - name: Validate skills.sh discovery
        shell: bash
        run: |
          set -o pipefail
          npx --yes skills@1.5.23 add . --list | tee /tmp/skills-list.txt
          perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' /tmp/skills-list.txt > /tmp/skills-list-plain.txt
          grep -q "Found 1 skill" /tmp/skills-list-plain.txt
          grep -q "diagnose-system-performance" /tmp/skills-list-plain.txt
      - name: Validate installer syntax
        run: sh -n scripts/install.sh
```

- [ ] **Step 3: Run the CI-contract check after implementation**

Run the command from Step 1 again.

Expected: PASS with exit code 0 and no output.

- [ ] **Step 4: Run repository validation**

Run:

```bash
set -o pipefail
npx --yes skills@1.5.23 add . --list | tee /tmp/skills-list.txt
perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' /tmp/skills-list.txt > /tmp/skills-list-plain.txt
grep -q "Found 1 skill" /tmp/skills-list-plain.txt
grep -q "diagnose-system-performance" /tmp/skills-list-plain.txt
sh -n scripts/install.sh
git diff --check
```

Expected: the skills CLI reports exactly one skill named `diagnose-system-performance`; all commands exit 0; `git diff --check` produces no output.
