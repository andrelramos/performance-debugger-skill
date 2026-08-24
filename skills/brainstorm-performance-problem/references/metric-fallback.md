# When the metric does not exist

A missing metric never ends a thread. It changes the question from "what does the metric say" to "what is the cheapest way to answer this question".

Work the ladder from rung 0 upward. Present the first rung that can answer the current question, state what that rung cannot answer, and let the user choose. Skipping to rung 3 before exhausting rungs 0 and 1 is the most common failure in this interview: it spends a deployment to learn something an existing log already contained.

Every rung you climb is also an observability finding. Record it before moving on.

## The ladder

| Rung | What it is | Time to first data | Risk |
|---|---|---|---|
| 0 | Data already collected and never read | minutes | none |
| 1 | An indirect proxy for the same mechanism | minutes | misattribution |
| 2 | Cheap bounded sampling | minutes to hours | overhead, cardinality |
| 3 | Minimal instrumentation answering one question | one deployment | code change, cardinality, cost |
| 4 | Controlled experiment | hours to days | production impact |

### Rung 0 — Data you already have

Before anything else, list what is already being written and nobody has opened. In most systems this includes far more than the user remembers:

- load balancer, ingress, or reverse proxy access logs, which usually carry per-request duration, upstream time, status, and size;
- application logs with timestamps, which yield a duration by subtraction even when no timer was ever added;
- the database's own slow query log, statement statistics, wait events, and lock views;
- the cloud provider's default per-resource metrics for compute, storage, database, queue, and load balancer;
- the runtime's built-in counters: GC statistics, thread and event-loop state, pool gauges, heap size;
- the orchestrator's restart counts, OOM kills, throttling counters, and resource limits;
- deployment, migration, and configuration change history, which answers F2 without any metric at all.

Ask specifically, one source at a time. "Do you have metrics?" gets "no". "Is there an nginx or ALB access log for that endpoint?" gets "yes, probably".

**Cannot answer:** anything requiring a dimension the source never recorded. An access log with no tenant field cannot segment by tenant.

### Rung 1 — Indirect proxies

When the direct signal is absent, another signal driven by the same mechanism may already exist. A proxy is valid only when the mechanism connecting it to the question is stated out loud.

| Question you cannot answer directly | Usable proxy | What the proxy does not prove |
|---|---|---|
| Is the connection pool exhausted? | acquisition timeouts, or request concurrency versus pool size | whether the hold time or the arrival rate caused it |
| Are GC pauses hurting the tail? | GC CPU time, collection count, or heap after collection | that pauses coincide with the slow requests |
| Is a query slow, or is the lock wait? | transaction duration versus statement duration | which statement holds the lock |
| Did latency degrade? | timeout rate and error rate at the caller | the shape of the distribution below the timeout |
| Is one instance degraded? | per-instance request count under a round-robin balancer | why that instance differs |
| Did payload size grow? | bytes sent per response, or storage growth rate | which field grew |
| Is the cache degraded? | backend query rate per request | whether hit ratio or invalidation changed |

**Cannot answer:** anything where a second mechanism could produce the same proxy movement. Always name that alternative when you present a proxy.

### Rung 2 — Cheap sampling

Bound the collection before starting it. State all four bounds explicitly: sampling rate, duration, dimensions kept, and stop condition.

Sound sampling choices:

- profile at a low sampling frequency on one instance rather than all of them;
- capture full traces for a small percentage of requests, biased toward slow ones if the tooling supports it;
- log the decomposition for a single endpoint rather than for every route;
- snapshot pool and queue gauges every few seconds for a bounded window;
- run the database's own statement statistics view, which is usually already accumulating.

Keep dimensions few. Cardinality, not volume, is what makes sampling expensive: a per-user label on a million users costs far more than a hundred times the request rate.

**Cannot answer:** rare events. A one percent sample of an event occurring in one request per thousand will not find it. When the target is rare, sample by condition — slow, failed, or large — rather than by rate.

### Rung 3 — Minimal instrumentation

One metric, or one span, that answers exactly one named question. Write the question first, then the instrument. If the question cannot be written in one sentence, the instrument is premature.

Rules:

- name the question in the code comment and in the dossier;
- choose the instrument type by what the question needs: a counter for rate, a histogram for distribution, a gauge for level, a span for decomposition, a structured log line for a rare discrete event;
- bound the labels before writing it, and never label with an unbounded identifier;
- add the removal condition — instrumentation added for one investigation either graduates deliberately or is deleted.

Prefer the boundary over the internals. A timer around a dependency call usually answers more than five timers inside the function that calls it.

**Cannot answer:** anything about the past. Instrumentation added today cannot establish yesterday's baseline, which is why rung 0 outranks it during an incident.

### Rung 4 — Controlled experiment

Reach this rung only when observation cannot separate the remaining hypotheses. Define, before starting: the hypothesis, the success metric, the duration limit, the abort condition, and the rollback.

In increasing risk:

1. reproduce locally with representative data volume — a shape reproduced at one percent of the data proves the mechanism, not the magnitude;
2. replay recorded traffic against staging;
3. load test an isolated environment with a stated arrival rate;
4. canary in production with an explicit blast radius;
5. reversible production change under observation.

Never run load against production without explicit authorization and confirmed headroom. Never bundle a fix with an experiment: a change that both tests a hypothesis and remediates it teaches nothing when it works.

**Cannot answer:** whether the reproduction matches production, unless the workload, data volume, and concurrency were matched deliberately.

## Translating a rung to the user's stack

The ladder is stack-agnostic on purpose. Turn it concrete at the moment of use:

1. Detect the stack from the repository — dependency manifests, configuration, container definitions, CI files — and from what the interview already revealed.
2. Confirm the detection with the user in one sentence before proposing a command.
3. Propose the concrete command, query, or code change for the chosen rung, in their language and their tooling.
4. State what the output will look like and which interview question it answers.

Never invent a tool the user has not shown they run. When the stack is unknown, describe the signal you need and ask what already produces it.

## Trust before collection

A metric that exists can still be wrong. Before building a conclusion on one, check:

- **aggregation:** an average of averages hides tails, and pre-aggregated percentiles cannot be re-aggregated across instances;
- **resolution:** a one-minute point cannot show a ten-second stall;
- **retention:** a baseline older than the retention window does not exist;
- **scope:** host-level metrics in a shared or containerized environment may describe a neighbor;
- **clock and window alignment:** two dashboards on different windows will disagree about ordering, and ordering is what F3 depends on;
- **collection gaps:** a flat line may mean the exporter stopped, not that the value stopped moving.

When a metric fails one of these checks, treat the signal as absent and enter the ladder. Say which check it failed and record it as observability debt.
