# Guidance for intermittently slow queries

## Objective

Add specific guidance to the diagnostic tree for cases where the same query shape is slow only during some executions. The guidance must help distinguish planning/optimization time from execution time and turn this variation into verifiable hypotheses.

## Location

Create a subsection within `4.1 Slow individual queries` in `skills/diagnose-system-performance/references/decision-tree.md`. This proximity keeps the new case in the branch where the agent already inspects plans, indexes, selectivity, and plan changes.

## Content

The subsection must instruct the agent to:

1. compare fast and slow executions of the same query shape, preserving parameters, cardinality, cache, and concurrency as analysis dimensions;
2. measure planning/optimization time separately from execution time, including the planner or equivalent component;
3. if planning/optimization is slow, evaluate an excessive number of candidate indexes, redundant or marginally relevant indexes, and statistics that make selection difficult;
4. verify whether heavy columns, such as vectors, files, binary data, BLOBs, or large documents, are included in an index, read with candidate rows/documents, or returned because projection is missing;
5. consider reducing or redesigning indexes only after confirming usage, redundancy, and impact, avoiding recommendations to remove them without evidence;
6. note that some databases, such as MongoDB, allow an index hint to limit the planner's choices;
7. treat an index hint only as a temporary, palliative, reversible, monitored mitigation because it forces a plan that may become unsuitable as data and workloads change.

## Safety and validation

The change is documentation-only. It must preserve the skill's evidence-driven method, separate diagnosis from correction, and avoid automatically concluding that too many indexes or a heavy column are the root cause. Validation must confirm that an agent can retrieve all the points above and does not recommend an index hint as the default solution.
