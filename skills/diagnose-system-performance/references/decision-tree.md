# Decision tree for performance problems

Use this tree as a map, not as a rigid checklist. Start with the signal most directly tied to the impact, and move across branches when there is evidence of interaction.

## Initial routing

| Dominant signal | Initial branch | First distinction |
|---|---|---|
| Slow responses or jobs | Latency | Did p50 also worsen, or only p95/p99? |
| Processing at the limit | CPU | All cores or only one? |
| Growing RAM usage or pauses | Memory and garbage collection | Retention, allocation, or external pressure? |
| Time concentrated in queries | Database | Slow query, volume, lock, or saturation? |
| Waiting to acquire a resource | Connections and pools | Insufficient capacity or abnormal retention? |
| Failures under load | Errors and timeouts | Origin, budget, and retry amplification? |
| I/O wait or slow storage | Disk and I/O | IOPS, throughput, latency, or queue? |
| Degraded remote calls | Network | RTT, loss, DNS, handshake, or round trips? |
| Backlog or insufficient throughput | Queues and throughput | Does arrival exceed service, or have consumers degraded? |

## 1. Latency

### 1.1 Establish scope

- Compare p50, p95, p99, maximum, and timeout rate; the average alone hides tail latency.
- Segment by operation, status, payload, tenant, instance, zone, version, and dependency.
- Break time down into queueing, application, database, external calls, serialization, and network.

### 1.2 If p50, p95, and p99 worsened together

Suspect systemic degradation or a common path:

- CPU or memory pressure across many instances;
- a slower database/dependency for most operations;
- a general increase in payload, volume, or algorithmic cost;
- a configuration, runtime, infrastructure, or deployment change;
- persistent queues caused by insufficient capacity.

Decisive measurements: tracing breakdown, service time versus wait time, profile by version, and comparison with a baseline at the same volume.

### 1.3 If p50 is stable, but p95/p99 worsened

Suspect sparse behavior:

- lock or pool contention;
- garbage collection pauses;
- retries and hedging;
- a degraded partition, shard, host, or zone;
- cache miss, cold start, or lazy initialization;
- large payloads and specific operations;
- noisy neighbor or throttling.

Decisive measurements: outlier traces, distribution by instance/partition, pool acquisition, pauses, and number of attempts.

### 1.4 If latency grows with demand

- Check whether the arrival rate is approaching the service rate.
- Look for invisible queues: executor, thread pool, event loop, socket backlog, connection pool, and database.
- Compare useful concurrency with blocked time.
- Test whether the cost per operation also grows; this indicates contention, lower cache effectiveness, or volume-dependent complexity.

## 2. CPU

### 2.1 All cores are highly utilized

Possible mechanisms:

- legitimate load above capacity;
- expensive algorithms, parsing, compression, cryptography, or serialization;
- retries, polling, or loops repeating work;
- garbage collection consuming CPU because of a high allocation rate;
- excessive context switches or runnable threads;
- queries/processing improperly moved into the application.

Collect a sampling CPU profile, request rate, cost per operation, allocations, retries, and run queue.

### 2.2 One highly utilized core with moderate aggregate CPU

Suspect:

- a saturated event loop or dispatcher;
- a global lock or serial section;
- a single partition/hot key;
- incorrect affinity;
- a single-threaded stage limiting a parallel pipeline.

Analyze CPU by core/thread and the throughput of the serial stage. Average machine CPU can hide this bottleneck.

### 2.3 CPU grows faster than volume

Investigate nonlinear complexity, average data size, cache hit ratio, contention, retries, and duplicated work. Normalize CPU by transaction and by byte processed.

### 2.4 High CPU without corresponding throughput

Look for spin locks, busy waiting, aggressive polling, a retry storm, unnecessary compression, excessive logging, cache invalidation, or garbage collection. Distinguish user, system, steal, and iowait time.

## 3. Memory and garbage collection

### 3.1 Memory grows continuously and does not return

Distinguish:

- actual retention of objects/references;
- an unbounded cache or unexpected cardinality;
- queues/backlogs held in memory;
- buffers, listeners, tasks, or connections that are not released;
- native/off-heap memory versus managed heap;
- fragmentation or expected allocator behavior.

Compare heap usage after a full collection, RSS/working set, native memory, object counts by class, and dominators across snapshots.

### 3.2 Spikes associated with an operation

Check for collection materialization, full-file reads, decompression, duplicate serialization, in-memory joins, and operation concurrency. Measure allocated bytes and peak usage per operation, not only global RAM.

### 3.3 Frequent garbage collection or long pauses

Ask:

- Did the allocation rate increase?
- Did the live set grow?
- Is the heap too small for the workload or too large for the pause target?
- Are there large objects, premature promotion, or fragmentation?
- Has garbage collection CPU displaced useful work?

Correlate pauses and garbage collection CPU time with p95/p99. Heap/collector tuning is a later hypothesis; first determine why allocation or retention changed.

### 3.4 Swap, page faults, or host pressure

If the heap appears healthy but latency worsens, check the total working set, neighboring containers, major page faults, swap, cgroup limits, and OOM kills. The problem may be outside the runtime.

## 4. Database

### 4.1 Slow individual queries

Inspect the actual plan, estimated versus actual rows, indexes, selectivity, join order, sorts, spills, scans, and parameters. Compare server time, connection acquisition, and result transfer.

Possible causes:

- a missing/inadequate or unused index;
- a plan change or parameter sensitivity;
- stale statistics;
- greater volume/cardinality;
- a sort/hash spill caused by insufficient memory;
- functions/conversions preventing efficient access;
- lock wait mistaken for slow execution.

#### 4.1.1 Same query shape is slow only in some executions

If the same query shape is intermittently slow, compare fast and slow executions with equivalent parameters, cardinality, cache, and concurrency. Separate planning or optimization time from execution time, and check whether different plans were selected or replanned.

If the planner/optimizer or equivalent component is slow:

- assess how many candidate indexes it considers and whether any indexes are redundant, overlapping, irrelevant to the query shape, or insufficiently selective; reduce or redesign indexes only after confirming usage, redundancy, and impact;
- check statistics, data distribution, and differences between estimates and actual cardinality;
- look for heavy columns, such as vectors, files, binary data, BLOBs, or large documents, and confirm whether they are included in any index, read from candidate rows/documents, or included in the result because projection is missing; keep these columns out of the critical path when they are not needed.

Some databases allow the planner's choice to be constrained with an index hint or equivalent mechanism; MongoDB is one example. Consider this only as a temporary, palliative, reversible, monitored mitigation for the affected query shapes: reducing candidate plans may prevent slow planning, but forcing an index removes some of the database's ability to adapt to changes in data and workload. Prefer fixing the indexes, statistics, projection, and modeling that cause the instability.

### 4.2 Many queries per operation

Look for N+1 queries, lazy loading, duplicate calls, chatty APIs, in-memory pagination, and missing batching. Measure queries per transaction and round trips, not only the average duration of each query.

### 4.3 Many rows or bytes read

Separate the number of rows from the number of bytes. A row can be heavy because of BLOBs, files, images, documents, large JSON values, arrays, biometric data, vectors, or embeddings.

Typical causal chain:

`heavy columns → more reads and transfer → more deserialization and allocation → higher CPU/garbage collection/network usage → worse latency and throughput`

Check column projection, filters, pagination, deferred access to heavy content, compression, and the storage model. Avoid `SELECT *` on critical paths without a demonstrated need.

### 4.4 Locks and transactions

Measure lock wait, blockers, deadlocks, and transaction duration and scope. Look for transactions left open during external calls, large batch operations, inconsistent lock ordering, and stronger isolation than necessary.

### 4.5 Saturated database

Correlate CPU, I/O, buffer/cache hit, memory, active sessions, queue, replica lag, and limits. Confirm whether the saturation comes from the workload under investigation or from neighbors. Scaling capacity may provide relief, but does not prove root cause.

## 5. Connections and pools

### 5.1 Long time to acquire a connection/resource

Measure utilization, wait queue, acquisition time, timeouts, churn, and usage duration.

Hypotheses:

- the pool is too small for current concurrency and retention time;
- connections are not returned or streams are not closed;
- slow transactions/queries retain the resource;
- the pool is so large that it saturates the destination;
- connection creation is expensive because connections are not reused;
- limits are misaligned across the application, proxy, and database.

Do not automatically increase the pool. Given the approximate relationship `concurrency in use ≈ rate × retention time`, reducing retention may be safer than adding connections.

### 5.2 Many threads or tasks waiting

Identify the shared resource: connection, lock, semaphore, socket, executor, or quota. A larger thread pool may only move the queue and increase memory/context switches.

## 6. Errors and timeouts

### 6.1 Establish the origin

- Who issued the timeout: client, proxy, application, database, or dependency?
- Does the budget decrease at each hop, or does each layer restart a full timeout?
- Did the operation continue after the client gave up?
- Is cancellation propagated?

### 6.2 Check for amplification

Retries can turn a small degradation into saturation. Measure attempts per operation, backoff, jitter, duplicate requests, success rate by attempt, and wasted load.

### 6.3 Useful patterns

- errors only under load: capacity, pool, quota, or queue;
- periodic errors: renewal, rotation, collection, batch, or autoscaling;
- timeouts with low CPU: blocking, dependency, pool, network, or I/O;
- 5xx errors after latency increases: likely a consequence, not necessarily the initial cause.

## 7. Disk and I/O

### 7.1 Distinguish the constraint

Observe latency, IOPS, throughput, operation size, queue depth, and iowait. High throughput does not imply good performance for small random I/O; high IOPS also do not explain large sequential operations.

### 7.2 Common hypotheses

- synchronous or excessively verbose logs;
- frequent fsync;
- cache misses and random reads;
- database/sort spill to disk;
- concurrent compaction, backup, or snapshot activity;
- shared volume/noisy neighbor;
- inode, space, or quota near the limit;
- reading/writing large files on the synchronous path.

Correlate the operation's I/O time with the device queue and activity from other processes.

## 8. Network

### 8.1 Separate components

Measure DNS, TCP connection, TLS, time to first byte, transfer, RTT, loss, retransmissions, and resets. Application tracing without these components may attribute network time to the remote service.

### 8.2 Common hypotheses

- many small round trips;
- no keep-alive or reuse;
- repeated handshake/DNS;
- loss and retransmissions;
- a path across zones/regions;
- a large payload or inadequate compression;
- a saturated proxy, service mesh, NAT, or load balancer;
- uneven load balancing or a degraded endpoint.

Compare by origin, destination, zone, protocol, and version. Avoid concluding "network" merely because an external call appears slow.

## 9. Queues and throughput

### 9.1 Growing backlog

Compare arrival rate, completion rate, effective concurrency, service time, and age of the oldest message.

- arrival > service: insufficient sustained capacity;
- service rate fell: consumer, dependency, lock, error, or cost change;
- concentrated backlog: partition/hot key or ordering;
- many redeliveries: failure, timeout, visibility window, or idempotency;
- high lag with idle consumers: assignment, polling, lease, or configuration.

### 9.2 Low throughput without a saturated resource

Look for a concurrency limit, serial stage, small batch, external wait, backpressure, rate limit, insufficient partitions, or excessive coordination.

### 9.3 High throughput with worse latency

There may be larger batches, deliberate queueing, or a trade-off between throughput and response time. Check whether the behavior meets the SLO before treating it as a regression.

## Cross-branch interactions

- Retry storm: timeout → retries → CPU/connections/database → more timeouts.
- Exhausted pool: slow query → connection retention → queue → high p99.
- Heavy objects/columns: database/network → allocation → garbage collection → tail latency.
- Backlog: slow service → higher memory usage → garbage collection/CPU → even slower service.
- Excessive logging: error/retry → disk and CPU → latency.
- Hot partition: uneven distribution → specific core/shard/queue saturated while global averages remain normal.
