import { describe, expect, it } from 'vitest'
import { isV1, migrateV1 } from '../src/migrate'

const V1 = {
  repo: 'demo',
  subtitle: 'phase 1',
  range: 'aa1..bb2',
  commits: [
    { sha: 'aa1111b', touches: 'parser', why: [['one line']], items: [{ title: 't', ps: ['x'] }] },
    { sha: 'bb2222c', touches: null, why: [], items: [] },
  ],
}

describe('migrateV1', () => {
  it('detects v1 sidecars', () => {
    expect(isV1(V1)).toBe(true)
    expect(isV1({ ...V1, schemaVersion: 2 })).toBe(false)
    expect(isV1(null)).toBe(false)
    expect(isV1({})).toBe(false)
  })

  it('stamps schemaVersion 2 and keeps every curated field', () => {
    const v2 = migrateV1(V1)
    expect(v2.schemaVersion).toBe(2)
    expect(v2.commits).toHaveLength(2)
    const first = v2.commits[0]
    expect(first).toBeDefined()
    expect(first?.sha).toBe('aa1111b')
    expect(first?.touches).toBe('parser')
    expect(first?.why).toEqual([['one line']])
    expect(first?.items?.[0]?.title).toBe('t')
  })

  it('fills missing why and items with empty arrays', () => {
    const sparse = { commits: [{ sha: 'cc3333d' }] }
    const v2 = migrateV1(sparse as unknown as Parameters<typeof migrateV1>[0])
    expect(v2.commits[0]).toMatchObject({ sha: 'cc3333d', why: [], items: [] })
  })
})
