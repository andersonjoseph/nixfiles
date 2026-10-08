export type RowKind = 'add' | 'del' | 'ctx'

export interface Row {
  kind: RowKind
  old: number
  new: number
  text: string
}

export interface Hunk {
  oldStart: number
  oldCount: number
  newStart: number
  newCount: number
  rows: Row[]
}

const HUNK_RE = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/

export function parseUnified(diff: string): Hunk[] {
  const hunks: Hunk[] = []
  let cur: Hunk | null = null
  let oldLn = 0
  let newLn = 0
  const lines = diff.endsWith('\n') ? diff.slice(0, -1).split('\n') : diff.split('\n')
  for (const line of lines) {
    const m = HUNK_RE.exec(line)
    if (m) {
      cur = {
        oldStart: Number(m[1]),
        oldCount: m[2] === undefined ? 1 : Number(m[2]),
        newStart: Number(m[3]),
        newCount: m[4] === undefined ? 1 : Number(m[4]),
        rows: [],
      }
      hunks.push(cur)
      oldLn = cur.oldStart
      newLn = cur.newStart
    } else if (cur && !line.startsWith('\\')) {
      if (line.startsWith('+')) {
        cur.rows.push({ kind: 'add', old: 0, new: newLn++, text: line.slice(1) })
      } else if (line.startsWith('-')) {
        cur.rows.push({ kind: 'del', old: oldLn++, new: 0, text: line.slice(1) })
      } else {
        cur.rows.push({ kind: 'ctx', old: oldLn++, new: newLn++, text: line.slice(1) })
      }
    }
  }
  return hunks
}

export function overlaps(hunk: Hunk, from: number, to: number): boolean {
  if (hunk.newCount > 0) {
    return hunk.newStart <= to && hunk.newStart + hunk.newCount - 1 >= from
  }
  return hunk.newStart >= from && hunk.newStart <= to + 1
}

export function selectHunks(hunks: Hunk[], from: number, to: number): Hunk[] {
  return hunks.filter((h) => overlaps(h, from, to))
}
