# Interview phases

Six phases, run in order. Each phase states its goal, its questions, its exit criterion, and what to do when the user cannot answer.

Ask one question per message. Prefer options over open prompts: a user who cannot produce a number can still recognize a range. Never present the phase table to the user as a form to fill in — the value is in the branching, not the checklist.

## Recording answers

Every answer becomes a fact line with provenance:

| Provenance | Meaning | Use |
|---|---|---|
| `measured` | read from a metric, log, trace, or query result now | can anchor a baseline and a conclusion |
| `estimated` | derived from another measured value | usable with the derivation stated |
| `recalled` | remembered from a past observation | a lead; must be re-measured before it anchors anything |
| `assumed` | neither measured nor remembered | must be listed as an assumption in the dossier |

When a fact would be `assumed` and the phase depends on it, that is a gap. Record the gap, add the observability debt item, and continue.

## F0 — Mode

**Goal:** set urgency and the collection budget before asking anything technical.

**Question:** Is this happening right now, did it start after a specific change, or is nothing broken yet?

| Answer | Mode | Consequence |
|---|---|---|
| Happening now, users affected | active incident | Favor rungs 0 and 1 of the fallback ladder; do not propose instrumentation that requires a deployment; keep the interview short and write the dossier early |
| Started at some point, still present | regression | The baseline exists in history. F2 is the highest-value phase; spend questions there |
| Nothing broken, want it faster | preventive optimization | No incident pressure. Require a target before proceeding: a number without a target cannot be judged good or bad |

**Also ask when the mode is incident:** who is currently authorized to change production, and is a rollback available? Do not plan any experiment the user cannot authorize.

**Exit:** mode chosen. In preventive mode, also a stated target (SLO, latency budget, throughput goal, or cost limit).

**If unanswerable:** treat as regression, state the assumption, continue.

## F1 — Impact and operation

**Goal:** replace "the system is slow" with a named operation and a measurable harm.

Ask in this order, one per message:

1. **Who notices it?** End users, an internal team, a batch job, a downstream service, or a monitor only. A problem only a dashboard notices is ranked differently from one a customer notices.
2. **Which operation?** Endpoint, screen, job, consumer, query, or report. If the answer is "everything", ask for the one the complaint arrived about — "everything" is almost never true and is usually an unsegmented view.
3. **How bad, in the user's terms?** Seconds waited, requests failed, reports not delivered, jobs missing their window.
4. **Which environment, and does it reproduce elsewhere?** Production only, staging too, one region, one tenant.

**Exit:** a named operation, a described harm with a number or a range, and an environment.

**If unanswerable:** the complaint may be a perception without a signal, which is a legitimate finding. Ask what the user saw that made them open this investigation, and record that as the only observed fact. Then go to the fallback ladder for the operation-level signal that would confirm or deny it. Do not proceed to F3 pretending a signal exists.

## F2 — Window, baseline, and change

**Goal:** make the degradation comparable. A number without a baseline is not evidence of degradation.

1. **When did it start?** Push for a boundary: a day, an hour, or "it has always been like this". "Always" moves the mode toward preventive optimization; say so and re-check F0.
2. **Is it continuous, periodic, or bursty?** Periodicity points at batches, cron, rotation, autoscaling, cache expiry, or traffic shape long before it points at code.
3. **What is the healthy comparison?** The same operation last week, the same hour yesterday, a different region, or a different tenant. Reject a comparison whose workload differs: a quiet Sunday is not a baseline for a Monday peak.
4. **What changed in that window?** Deployment, feature flag, configuration, schema or index, infrastructure, dependency version, traffic volume, payload size, or data volume. Ask for the change list even when the user is sure it is unrelated.
5. **Did demand change?** Request rate, concurrency, payload size, cardinality, and operation mix. Degradation with proportional demand growth is a capacity story, not a defect story.

**Exit:** a window with a start boundary, a comparable baseline, and a change list.

**If unanswerable:** most often retention is too short to hold the baseline. That is an observability finding of its own — record it, and use the earliest available healthy period while stating the risk that it is not comparable.

## F3 — Dominant signal

**Goal:** enter the right branch of the decision tree.

Ask what the user has already seen, not what they conclude: "which of these did you observe change?" beats "what do you think is the cause?".

Load `../diagnose-system-performance/references/decision-tree.md` and read only the selected branch. If unavailable, use the compact routing table below and record in the dossier that branch depth was reduced.

### Compact routing table

| Observed | Branch | First distinction |
|---|---|---|
| Slow responses or jobs | Latency | Did p50 also worsen, or only p95/p99? |
| Processing at its limit | CPU | All cores, or one? |
| Growing memory or pauses | Memory and GC | Retention, allocation rate, or host pressure? |
| Time concentrated in queries | Database | Slow query, query volume, lock, or saturation? |
| Waiting to acquire a resource | Connections and pools | Missing capacity, or abnormal hold time? |
| Failures under load | Errors and timeouts | Which hop emitted it, and is retry amplifying it? |
| I/O wait or slow storage | Disk and I/O | IOPS, throughput, latency, or queue depth? |
| Degraded remote calls | Network | RTT, loss, DNS, handshake, or round-trip count? |
| Backlog or insufficient throughput | Queues and throughput | Arrival above service, or degraded consumers? |

**When the user names more than one signal:** ask which one moved first. Order in time separates cause from consequence more cheaply than any other question. When the order is unknown, keep both branches open and mark the ambiguity — do not pick the familiar one.

**When the user names none:** they have no per-signal visibility. Go to the fallback ladder for the coarsest available signal, usually host metrics or proxy logs, and route from what it shows.

**Exit:** one branch selected and its first distinction answered, or two branches explicitly held open with the discriminating question named.

## F4 — Concentration and segmentation

**Goal:** decide whether the degradation is universal or sparse, and find the segment that carries it.

1. **Universal or sparse?** Does every request suffer, or only a tail? Universal points at a common path — capacity, a shared dependency, a global change. Sparse points at contention, pauses, retries, or one bad partition.
2. **Which segment carries it?** Ask across the dimensions the stack actually has: instance, zone, tenant, shard, partition, version, endpoint, payload size, status code. A degradation absent in a segment is as informative as one present.
3. **Where does the time go?** Decompose into queue wait, service time, dependencies, serialization, and network. Answer "unknown" honestly rather than assigning time by intuition.
4. **Does it scale with demand?** If cost per operation is flat and only volume grew, it is capacity. If cost per operation grew, something changed in the work itself.

**Exit:** universal versus sparse settled, and either an identified segment or a recorded gap that no segmentation is available.

**Contradiction rule:** if the segmentation contradicts the branch chosen in F3, say so explicitly and return to F3. Example: a CPU branch chosen from a host graph, but segmentation shows one tenant and flat CPU per request, is a routing error, not a CPU problem.

**If unanswerable:** an unsegmentable metric is one of the highest-value observability findings available. Record it, and use the fallback ladder to obtain a single dimension of segmentation — usually the cheapest one already present in an access log.

## F5 — Competing hypotheses

**Goal:** produce two to five hypotheses that a single measurement can separate.

For each hypothesis, record all six fields. A hypothesis missing any field is not finished:

1. **Mechanism** — one causal sentence, specific enough to predict something.
2. **Explains** — which recorded facts it covers.
3. **Predicts** — a signal that must exist if it is true.
4. **Refuted by** — a signal that would kill it, taken from the branch's "Signals that rule out" block. If nothing could refute it, it is not a hypothesis.
5. **Discriminating measurement** — the cheapest observation separating it from the others, with its rung on the fallback ladder.
6. **Confidence** — low, medium, or high, justified by the provenance of the facts it rests on. Hypotheses resting only on `recalled` facts are capped at low.

**Ranking:** order by `plausibility × impact × ease of discrimination`. Familiarity is not a ranking criterion. When two hypotheses share one discriminating measurement, that measurement is the decisive next step.

**One hypothesis is a warning sign.** A single hypothesis usually means the interview stopped at the first familiar explanation. Ask what else would produce the same observations, including the answers "demand grew legitimately" and "nothing degraded; the baseline was wrong".

**Exit:** two to five complete hypotheses and one named decisive measurement.

## Closing

Write the dossier, set its state, rank the observability debt, and offer the handoff. Do not append a remediation section, even when the cause looks obvious — the handoff exists for that.
