# Evidence-driven investigation method

## 1. Define the problem contract

Before looking for the cause, turn "it is slow" into a measurable statement:

- **Impact:** who or what was affected, and how severely?
- **Operation:** which endpoint, job, consumer, query, flow, or screen?
- **Window:** when did it start, how long did it last, and is it still occurring?
- **Baseline:** how does the same signal behave during a comparable healthy baseline?
- **Demand:** request rate, concurrency, payload size, cardinality, and operation mix.
- **Changes:** deployment, flag, configuration, index, schema, infrastructure, dependency, traffic, or data.
- **Objective:** SLO, latency budget, expected throughput, or resource limit.

Avoid comparing periods with incompatible workloads. Normalize by volume, operation, and size when necessary.

## 2. Use the reasoning chain

Keep every conclusion traceable:

1. **Degraded metric:** p99, CPU, RSS, GC pause, lock wait, lag, etc.
2. **Observed behavior:** gradual, abrupt, periodic, per instance, per operation, or per load level.
3. **Subsystem involved:** application, runtime, database, pool, disk, network, queue, or dependency.
4. **Hypothesis:** a mechanism that predicts verifiable signals.
5. **Possible root cause:** the condition that originated the mechanism and explains the onset.

Example: p99 increased while p50 remained unchanged → only some requests wait for a connection → pool acquisition accounts for most of the time → pool exhaustion hypothesis → possible root cause: connections held by long-running transactions after a deployment.

## 3. Correlate without confusing correlation with causation

A high metric during the incident is evidence of correlation. To support causation, look for at least two of these elements:

- a consistent temporal sequence;
- a plausible technical mechanism;
- segmentation that tracks the impact;
- a prediction confirmed by a new measurement;
- controlled reproduction;
- improvement after removing or limiting the factor, with safe rollback.

Do not conclude that "CPU caused latency" merely because both increased. CPU usage may be an effect of retries, serialization, GC, or a legitimate increase in demand.

## 4. Decompose before optimizing

### Latency

Separate, when possible:

`total latency = queue wait + service time + dependencies + serialization + network`

Compare p50, p95, and p99. A degraded tail with a stable median suggests contention, outliers, pauses, retries, or specific partitions.

### Capacity

Relate arrival rate to service rate. When sustained arrivals approach or exceed capacity, small variations create queues and long tails.

### Resources

Look for saturation, contention, and waste separately:

- **Saturation:** a resource near its useful limit.
- **Contention:** blocked work competing for a resource.
- **Waste:** repeated or unnecessary work, such as polling, retries, and N+1 queries.

## 5. Build discriminating hypotheses

Use this template for each hypothesis:

- **Hypothesis:** a specific causal statement.
- **Explains:** which observations it covers.
- **Predicts:** which other signal should exist if it is correct.
- **Contradictions:** which current data weakens it.
- **Decisive measurement:** the smallest data collection or experiment that distinguishes it from competing hypotheses.
- **Collection risk:** cost, overhead, privacy, and operational impact.

Prioritize by `plausibility × impact × ease of discrimination`, not merely by familiarity.

## 6. Select instruments

Choose the instrument that answers the question:

- **Metrics:** trends, saturation, frequency, and comparison over time.
- **Tracing:** decomposition of an operation and its critical dependencies.
- **Profiling:** where CPU, allocations, locks, or execution time are consumed.
- **Structured logs:** discrete events, errors, retries, cardinality, and context.
- **Execution plans:** query paths, estimates, reads, joins, sorts, and spills.
- **Dumps/snapshots:** memory retention, blocked threads, and rare states.

Reduce the cardinality and duration of expensive data collection. Remove or protect sensitive data.

## 7. Experiment safely

Prefer this order:

1. read-only observation;
2. historical comparison;
3. local or staging reproduction;
4. canary with an explicit limit;
5. reversible production change.

Before the experiment, define the hypothesis, success metric, duration limit, stop condition, and rollback. Do not run load in production without explicit authorization and confirmed capacity.

## 8. Conclude without false certainty

Classify the result:

- **Confirmed:** the mechanism and cause explain the evidence, and a prediction was validated.
- **Probable:** the evidence converges, but decisive validation is still missing.
- **Inconclusive:** insufficient data or hypotheses that are still indistinguishable.
- **Refuted:** a prediction is incompatible with the data.

Always keep observed facts separate from inferences.
