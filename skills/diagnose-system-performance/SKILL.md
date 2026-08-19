---
name: diagnose-system-performance
description: Diagnoses system performance bottlenecks, regressions, and incidents with an evidence-driven decision tree covering latency, CPU, memory, garbage collection, databases, connections, errors, disk, network, and queues. Use when systems are slow, throughput is low, resources are saturated or consumed abnormally, timeouts occur, performance degrades after a deployment, or a root cause must be investigated. Do not use to justify optimizations without metrics or to run destructive load tests without authorization.
---

# Diagnose System Performance

Guide the investigation from the symptom to testable hypotheses. Answer in the user's language, and adapt commands, metrics, and examples to the identified stack.

## Required principles

1. Start with evidence, never with a preferred solution.
2. Preserve the chain: degraded metric → observed behavior → subsystem → hypothesis → possible root cause.
3. Compare the degraded window, healthy baseline, and changes in workload, configuration, or deployment.
4. Distinguish correlation, causal mechanism, and a proven root cause.
5. Keep diagnosis and remediation separate. Implement changes only when the user asks.
6. State gaps, assumptions, and confidence level. Do not invent missing metrics.
7. Prefer read-only checks. Before invasive profiling, load testing, restarts, production changes, or expensive queries, explain the risk and obtain authorization.

## Load references

- Always read `references/investigation-method.md` before conducting the investigation.
- Consult `references/decision-tree.md` and initially load only the branches compatible with the dominant signal. Expand to adjacent branches when evidence indicates interaction.
- Use `references/response-template.md` to structure the findings and checkpoints.

## Workflow

### 1. Frame the problem

Record the impact, service or operation, environment, time window, baseline, affected percentiles, volume, and recent changes. If essential data is missing, ask a few high-value questions while continuing with available safe checks.

### 2. Confirm and segment the signal

Validate the metric with a second view when possible. Segment by endpoint, operation, instance, zone, tenant, payload, status, version, and interval. Look for an abrupt onset, gradual growth, periodicity, and relationship to demand.

### 3. Choose the initial branch

Classify the dominant signal as latency, CPU, memory/GC, database, connections, errors/timeouts, disk/I/O, network, or queues/throughput. Do not treat the classification as a conclusion: resources interact, and the branch may change.

### 4. Form competing hypotheses

Create two to five ranked hypotheses. For each one, state the mechanism, supporting evidence, contrary evidence, and the least expensive measurement that can distinguish it.

### 5. Instrument and test

Use tracing, profiling, structured logs, per-resource metrics, and query execution plans as appropriate for the branch. Prefer small, reversible, isolated experiments. Advance a hypothesis only when it produces an observable prediction.

### 6. Conclude or iterate

Mark each hypothesis as confirmed, weakened, or inconclusive. If none explains all the evidence, return to the last proven point and reclassify the branch; do not force a narrative.

### 7. Recommend the next action

Prioritize actions by risk reduction and information gain. When evidence supports a root cause, propose remediation, validation, regression testing, and rollback signals without making changes outside the authorized scope.

## Completion criteria

Consider the diagnosis sufficient only when the symptom has been reproduced or clearly bounded, the mechanism is compatible with all relevant evidence, the primary hypothesis has been distinguished from alternatives, and there is a method to validate the remediation. If any item is missing, provide a partial diagnosis and the next decisive step.
