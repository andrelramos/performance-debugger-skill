# Diagnostic response structure

Use a level of detail proportional to the problem. Do not fill fields with assumptions presented as facts.

## Executive summary

- **Impact:**
- **Dominant signal:**
- **Diagnostic status:** confirmed, probable, or inconclusive
- **Primary hypothesis:**
- **Next decisive action:**

## Observed evidence

List facts only, including the window, unit, segment, and source when available.

| Evidence | Healthy baseline | Degraded window | Limited interpretation |
|---|---:|---:|---|
| Example: endpoint p99 | 180 ms | 2.4 s | The tail degraded |

## Decomposition

Show where time or resources are concentrated. Distinguish wait time from service time.

## Ranked hypotheses

For each hypothesis:

1. **Mechanism**
2. **Supporting evidence**
3. **Contradictory or missing evidence**
4. **Discriminating measurement/experiment**
5. **Collection risk**
6. **Confidence:** low, medium, or high

## Investigation plan

Order by information gain and safety:

1. read-only verification;
2. additional collection/segmentation;
3. controlled reproduction;
4. reversible experiment, if authorized.

Include the expected result for each hypothesis; "collect more logs" without a specific question is not a sufficient step.

## Root cause and correction

Use this section only when the evidence supports the mechanism. Separate:

- root cause;
- contributing factors;
- immediate correction;
- structural correction;
- regression/performance test;
- validation metrics;
- rollback condition.

## Gaps and limitations

Record unavailable data, assumptions, possible sampling biases, and what would prevent a stronger conclusion.
