import type { Sidecar } from './render'

export function isV1(raw: unknown): raw is Record<string, unknown> {
  return (
    typeof raw === 'object' &&
    raw !== null &&
    Array.isArray((raw as Record<string, unknown>).commits) &&
    (raw as Record<string, unknown>).schemaVersion !== 2
  )
}

export function migrateV1(raw: Record<string, unknown>): Sidecar {
  const sidecar = { ...raw, schemaVersion: 2 } as Sidecar
  sidecar.commits = sidecar.commits.map((c) => ({
    ...c,
    why: c.why ?? [],
    items: c.items ?? [],
  }))
  return sidecar
}
