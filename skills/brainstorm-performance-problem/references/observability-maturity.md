# Observability that serves investigation

Use this reference twice: when recording a gap during the interview, and when ranking the debt at the end.

The goal is not to reach a level. The goal is to be able to answer the next question. A system with one well-chosen histogram and a change log answers more than a system with two hundred unread dashboards.

## Levels

Levels describe what a system can answer, not what it collects.

| Level | The system can tell you | Typical ceiling |
|---|---|---|
| 0 | Something is wrong, because a person said so | Cannot bound a window or a baseline. Every investigation starts from a story |
| 1 | What happened, from logs, at the moment it was logged | Discrete events only. No rate, no distribution, no comparison |
| 2 | How saturated the machines are | Answers "the host is busy", never "which operation is slow" |
| 3 | Rate, errors, and latency distribution per operation | Locates the operation and the shape of the degradation. Cannot decompose a request across services |
| 4 | Where the time went inside a request, across services | Decomposes latency and dependencies. Cannot say which code consumed the CPU |
| 5 | Which code and which allocations consumed the resource, correlated with the slow requests | Diminishing returns without levels 3 and 4 underneath |

Levels are cumulative in usefulness but not in cost order. Level 3 is usually the highest-value step from anywhere below it, and the cheapest to reach, because request-level rate, errors, and duration are already latent in access logs at level 1.

## Mapping a gap to what would close it

Record the gap in the terms of the question it blocked, not in the terms of a product to buy.

| Interview question that stalled | Missing capability | Level |
|---|---|---|
| Which operation is slow? | duration by operation | 3 |
| Did the tail degrade or the whole distribution? | latency histogram, not an average | 3 |
| Was it always like this? | retention long enough to hold a baseline | 1–3 |
| What changed at that time? | deployment, flag, and configuration change history | 1 |
| Which instance, tenant, or shard? | one segmenting dimension on the existing signal | 3 |
| Where did the time go inside the request? | tracing across the dependency boundaries | 4 |
| Is the pool or queue the bottleneck? | pool and queue gauges from the runtime | 2–3 |
| Which query, and how often per request? | statement statistics and queries per operation | 3 |
| Why is CPU high? | sampling profiler, ideally continuous | 5 |
| Is the slowness the same event the user reported? | correlation identifier shared across logs, traces, and metrics | 4 |

## Ranking the debt

Rank by what this investigation would have gained, not by maturity:

`value = (number of interview questions the signal would have answered) × (weight of the phase it blocked) ÷ (cost to obtain)`

Weight the phases by how much the investigation depends on them: a gap that blocked F2's baseline or F3's routing is worth more than one that blocked a detail inside F4, because the earlier gap put the whole branch selection at risk.

Cost includes the parts people forget: cardinality growth, storage and vendor cost, the deployment required, the maintenance of a dashboard nobody owns, and the alert that will page someone at three in the morning.

Present at most five items, ordered, each with: the question it would have answered, what to add, the level it reaches, the rough cost, and the first thing to do. An unranked list of twenty improvements produces no action.

## The reasoning that keeps teams stuck

**A signal exists to answer a question.** Instrumentation added without a written question becomes a dashboard nobody reads and a bill nobody questions. Write the question first; it also tells you the instrument type.

**Cardinality is the real budget.** Cost scales with the number of distinct label combinations, not with request volume. User, request, session, URL with parameters, and raw error strings are unbounded and must never be metric labels. When a dimension is genuinely unbounded but needed, it belongs in a trace, an exemplar, or a structured log — not on a metric.

**Retention decides which baselines exist.** Comparing to last month requires a month of data at a resolution that still shows the shape. Short retention at high resolution plus long retention at low resolution answers more than either alone.

**Averages hide the thing you are looking for.** Most performance complaints are tail complaints. A histogram costs slightly more than a gauge and answers a different class of question. Percentiles pre-computed per instance cannot be averaged into a fleet percentile — the arithmetic does not work.

**Rate, errors, and duration for what you serve; utilization, saturation, and errors for what you own.** Requests and operations get RED; CPU, memory, disk, pools, and queues get USE. Most gaps found in this interview are one missing member of one of those two triples.

**Correlation across signals matters more than any single signal.** A trace ID in the logs, an exemplar on the histogram, and a shared timestamp convention convert three separate sources into one investigation. Without correlation, level 4 tooling still yields level 2 answers.

**Sampling is a design decision, not a default.** Uniform sampling loses exactly the rare events investigations need. Bias toward slow, failed, and large.

**Instrumentation has an owner and an end.** Anything added for one investigation either graduates deliberately, with its question written down, or gets removed. Otherwise the next investigation happens inside the noise this one created.
