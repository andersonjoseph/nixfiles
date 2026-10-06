import { describe, expect, it } from 'vitest'
import { overlaps, parseUnified, selectHunks } from '../src/diff'

const DIFF = [
  'diff --git a/file.ts b/file.ts',
  'index 1111111..2222222 100644',
  '--- a/file.ts',
  '+++ b/file.ts',
  '@@ -10,4 +10,5 @@ fn top()',
  ' context',
  '-old line',
  '+new line',
  '+added line',
  ' more context',
  '@@ -40,2 +41,0 @@ fn bottom()',
  '-gone one',
  '-gone two',
  '\\ No newline at end of file',
].join('\n')

describe('parseUnified', () => {
  it('skips file headers and the no-newline marker', () => {
    const hunks = parseUnified(DIFF)
    expect(hunks.length).toBe(2)
    expect(hunks[0]!.rows.map((r) => r.text)).toEqual([
      'context',
      'old line',
      'new line',
      'added line',
      'more context',
    ])
  })

  it('tracks old and new line numbers per row', () => {
    const rows = parseUnified(DIFF)[0]!.rows
    expect(rows[0]).toMatchObject({ kind: 'ctx', old: 10, new: 10 })
    expect(rows[1]).toMatchObject({ kind: 'del', old: 11, new: 0 })
    expect(rows[2]).toMatchObject({ kind: 'add', old: 0, new: 11 })
    expect(rows[3]).toMatchObject({ kind: 'add', old: 0, new: 12 })
    expect(rows[4]).toMatchObject({ kind: 'ctx', old: 12, new: 13 })
  })

  it('defaults a missing count to one', () => {
    const hunks = parseUnified('@@ -5 +5 @@\n same')
    expect(hunks[0]).toMatchObject({ oldStart: 5, oldCount: 1, newStart: 5, newCount: 1 })
  })
})

describe('overlaps', () => {
  it('meets the range on new-file numbers', () => {
    const hunk = { oldStart: 10, oldCount: 4, newStart: 10, newCount: 5, rows: [] }
    expect(overlaps(hunk, 12, 20)).toBe(true)
    expect(overlaps(hunk, 5, 9)).toBe(false)
    expect(overlaps(hunk, 15, 20)).toBe(false)
    expect(overlaps(hunk, 14, 14)).toBe(true)
  })

  it('keeps a pure deletion hunk visible inside or just past the range', () => {
    const del = { oldStart: 40, oldCount: 2, newStart: 41, newCount: 0, rows: [] }
    expect(overlaps(del, 41, 41)).toBe(true)
    expect(overlaps(del, 30, 40)).toBe(true)
    expect(overlaps(del, 30, 39)).toBe(false)
    expect(overlaps(del, 42, 50)).toBe(false)
  })

  it('selects only overlapping hunks in order', () => {
    const hunks = parseUnified(DIFF)
    expect(selectHunks(hunks, 10, 14).length).toBe(1)
    expect(selectHunks(hunks, 10, 14)[0]!.newStart).toBe(10)
    expect(selectHunks(hunks, 41, 41).length).toBe(1)
    expect(selectHunks(hunks, 10, 60).length).toBe(2)
    expect(selectHunks(hunks, 1, 5).length).toBe(0)
  })
})
