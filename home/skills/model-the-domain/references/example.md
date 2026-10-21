# Example: five booleans vs one union

Domain: a background job that queues, runs, and ends one of three ways.

## Before: scattered booleans

```ts
export interface Job {
  id: string
  queued: boolean
  running: boolean
  succeeded: boolean
  failed: boolean
  cancelled: boolean
  error?: Error
  result?: string
}

export function start(job: Job) {
  if (job.queued && !job.running && !job.succeeded && !job.failed && !job.cancelled) {
    job.queued = false
    job.running = true
  }
}

export function finish(job: Job, result: string) {
  if (job.running && !job.cancelled) {
    job.running = false
    job.succeeded = true
    job.result = result
  }
}

export function fail(job: Job, error: Error) {
  if (job.running && !job.succeeded) {
    job.running = false
    job.failed = true
    job.error = error
  }
}

export function cancel(job: Job) {
  if (!job.succeeded && !job.failed) {
    job.cancelled = true
    job.running = false
  }
}

export function label(job: Job): string {
  if (job.cancelled) return "cancelled"
  if (job.failed) return "failed"
  if (job.succeeded) return "done"
  if (job.running) return "running"
  if (job.queued) return "queued"
  return "unknown"
}
```

Costs:

- Five booleans give 32 combinations. Six are legal.
- `succeeded && failed` is representable. The domain has no such state.
- Every function re-derives the state from flags, and each guard can drift.
- `label()` needs an `"unknown"` return for contradictory flags.
- A new "retrying" state touches every guard.

## After: one discriminated union

```ts
export type Job =
  | { id: string; state: "queued" }
  | { id: string; state: "running"; startedAt: number }
  | { id: string; state: "succeeded"; result: string }
  | { id: string; state: "failed"; error: Error; attempts: number }
  | { id: string; state: "cancelled"; reason: string }

export type JobEvent =
  | { type: "start"; now: number }
  | { type: "finish"; result: string }
  | { type: "fail"; error: Error }
  | { type: "cancel"; reason: string }

export function step(job: Job, event: JobEvent): Job {
  switch (event.type) {
    case "start":
      return job.state === "queued"
        ? { ...job, state: "running", startedAt: event.now }
        : job
    case "finish":
      return job.state === "running"
        ? { ...job, state: "succeeded", result: event.result }
        : job
    case "fail":
      return job.state === "running"
        ? { ...job, state: "failed", error: event.error, attempts: 1 }
        : job
    case "cancel":
      return job.state === "queued" || job.state === "running"
        ? { ...job, state: "cancelled", reason: event.reason }
        : job
  }
}

export function label(job: Job): string {
  return job.state
}
```

Gains:

- Illegal states are unrepresentable. No value of type `Job` is both
  succeeded and failed.
- Each state carries its own data. `startedAt` exists only on `running`,
  `error` only on `failed`.
- Guards live in one switch. `cancel` states its legal source states instead
  of negating three flags.
- `label` is the state. `"unknown"` is gone.
- Adding `retrying` costs one union member and one case. An
  exhaustive-switch check flags every switch that misses it.
- Tests are countable: states times events, 5 x 4 = 20 cells to assert.

If the domain has two states and no data per state, a boolean pair is fine.
This principle targets scattered lifecycle flags, not every conditional.
