# skills.sh Publishing Design

## Objective

Make the public repository easy to discover, install, and validate with the skills CLI and skills.sh while preserving the existing portable skill layout and custom installer.

## Repository Layout

Keep the canonical skill at `skills/diagnose-system-performance/`. This path is already a standard discovery location for the skills CLI, and the `name` field matches its parent directory. Do not move or duplicate `SKILL.md`.

## Public Metadata

Add the MIT license text at the repository root and declare `license: MIT` in the skill frontmatter. Add `metadata.author: andrelramos` as a string value. Do not add compatibility restrictions because the skill has no required runtime, package, or network dependency.

## Installation Documentation

Add the official skills.sh badge for `andrelramos/performance-debugger-skill` near the top of `README.md`. Add a primary installation section with these commands:

```bash
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance
npx skills add andrelramos/performance-debugger-skill --skill diagnose-system-performance --global
```

Keep the existing custom installer documentation as an alternative for users who want its backup and multi-target behavior.

## Automated Validation

Add `.github/workflows/validate-skill.yml` for pushes and pull requests. The workflow must:

1. check out the repository with `actions/checkout@11d5960a326750d5838078e36cf38b85af677262` and `persist-credentials: false`;
2. install Node.js 22 with `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020`;
3. run `npx --yes skills@1.5.23 add . --list` and retain its output;
4. assert that the output contains `diagnose-system-performance`;
5. run `sh -n scripts/install.sh`.

The validation must not install the skill into an agent directory or modify repository files.

## Acceptance Criteria

- The skills CLI discovers exactly one public skill named `diagnose-system-performance`.
- `SKILL.md` has valid Agent Skills frontmatter with matching directory name, MIT licensing, and string metadata.
- The README presents skills.sh as the primary installation path and retains the custom installer as an alternative.
- The CI workflow detects discovery, frontmatter, or installer syntax regressions.
- No existing diagnostic guidance or runtime behavior changes.
