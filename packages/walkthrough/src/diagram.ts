import { esc } from './html'

export interface StatesDiagram {
  kind: 'states'
  rows: { from: string; to: string; dir: 'add' | 'del'; note?: string }[]
}

export interface SeqDiagram {
  kind: 'seq'
  actors: string[]
  msgs: { from: string; to: string; text: string; tone?: 'bad' | 'good' }[]
}

export interface TreeNode {
  label: string
  mark?: 'add' | 'del'
  file?: string
  children?: TreeNode[]
}

export interface TreeDiagram {
  kind: 'tree'
  root: string
  children: TreeNode[]
}

export type Diagram = StatesDiagram | SeqDiagram | TreeDiagram | string[]

export class DiagramError extends Error {}

function bad(msg: string): never {
  throw new DiagramError(msg)
}

function isStates(d: Diagram): d is StatesDiagram {
  return typeof d === 'object' && d !== null && (d as StatesDiagram).kind === 'states'
}

function isSeq(d: Diagram): d is SeqDiagram {
  return typeof d === 'object' && d !== null && (d as SeqDiagram).kind === 'seq'
}

function isTree(d: Diagram): d is TreeDiagram {
  return typeof d === 'object' && d !== null && (d as TreeDiagram).kind === 'tree'
}

function statesHtml(d: StatesDiagram): string {
  if (!Array.isArray(d.rows) || d.rows.length === 0) bad('states: rows must be a non-empty array')
  const out = ['<div class="states">']
  for (const [i, r] of d.rows.entries()) {
    if (!r?.from || !r?.to) bad(`states: row ${i + 1} needs from and to`)
    if (r.dir !== 'add' && r.dir !== 'del') bad(`states: row ${i + 1} dir must be add or del`)
    const toCls = r.dir === 'add' ? 'st-ok' : 'st-x'
    const note = r.note ? ` <span class="dim">${esc(r.note)}</span>` : ''
    out.push(
      `  <div class="${r.dir}"><span class="st">${esc(r.from)}</span><span class="ar">&#8594;</span><span class="st ${toCls}">${esc(r.to)}</span>${note}</div>`,
    )
  }
  out.push('</div>')
  return out.join('\n')
}

function treeHtml(d: TreeDiagram): string {
  if (!d.root) bad('tree: root is required')
  const out = ['<ul class="tree">', `  <li>${esc(d.root)}`]
  function walk(nodes: TreeNode[], depth: number, lines: string[]): void {
    if (!Array.isArray(nodes) || nodes.length === 0) return
    lines.push('    <ul>')
    for (const [i, n] of nodes.entries()) {
      if (!n?.label) bad(`tree: node at depth ${depth + 1} position ${i + 1} needs a label`)
      if (depth + 1 >= 3 && n.children?.length) bad(`tree: nesting deeper than three levels under ${n.label}`)
      const cls = n.mark ? ` class="${n.mark}"` : ''
      const sig = n.mark ? `<span class="sig">${n.mark === 'add' ? '+' : '-'}</span>` : ''
      const file = n.file ? ` <span class="dim">${esc(n.file)}</span>` : ''
      lines.push(`      <li${cls}>${sig}${esc(n.label)}${file}`)
      walk(n.children ?? [], depth + 1, lines)
      lines.push('      </li>')
    }
    lines.push('    </ul>')
  }
  walk(d.children ?? [], 0, out)
  out.push('  </li>', '</ul>')
  return out.join('\n')
}

const SEQ_SLOT = 150
const SEQ_BOX_W = 96
const SEQ_BOX_H = 26
const SEQ_TOP = 8
const SEQ_MSG_TOP = 60
const SEQ_MSG_STEP = 26

function seqSvg(d: SeqDiagram, uid: string): string {
  const actors = d.actors ?? []
  if (actors.length < 2 || actors.length > 6) bad('seq: two to six actors')
  const names = actors.map((a) => String(a ?? ''))
  if (names.some((n) => !n)) bad('seq: every actor needs a name')
  if (new Set(names).size !== names.length) bad('seq: actor names must be unique')
  const msgs = d.msgs ?? []
  if (msgs.length === 0) bad('seq: msgs must be a non-empty array')
  if (msgs.length > 14) bad('seq: at most 14 messages, split the story')
  for (const [i, m] of msgs.entries()) {
    if (!m?.text) bad(`seq: message ${i + 1} needs text`)
    if (!names.includes(m.from)) bad(`seq: message ${i + 1} from "${m.from}" is not an actor`)
    if (!names.includes(m.to)) bad(`seq: message ${i + 1} to "${m.to}" is not an actor`)
    if (m.from === m.to) bad(`seq: message ${i + 1} is a self message, write it as a note instead`)
    if (m.tone !== undefined && m.tone !== 'bad' && m.tone !== 'good') {
      bad(`seq: message ${i + 1} tone must be bad or good`)
    }
  }
  const laneX = (i: number) => SEQ_BOX_W / 2 + 6 + i * SEQ_SLOT
  const W = laneX(names.length - 1) + SEQ_BOX_W / 2 + 6
  const H = SEQ_MSG_TOP + msgs.length * SEQ_MSG_STEP + 12
  const laneBottom = H - 6
  const out: string[] = []
  out.push(`<svg class="seq" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" role="img">`)
  for (const tone of ['', '-bad', '-good']) {
    const fill = tone === '-bad' ? '#f63d68' : tone === '-good' ? '#6fae54' : '#5fc2a4'
    out.push(
      `  <defs><marker id="ah${tone}-${uid}" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="${fill}"/></marker></defs>`,
    )
  }
  names.forEach((n, i) => {
    const x = laneX(i)
    out.push(
      `  <line class="lane" x1="${x}" y1="${SEQ_TOP + SEQ_BOX_H}" x2="${x}" y2="${laneBottom}"/>`,
      `  <rect class="actor" x="${x - SEQ_BOX_W / 2}" y="${SEQ_TOP}" width="${SEQ_BOX_W}" height="${SEQ_BOX_H}" rx="5"/>`,
      `  <text x="${x}" y="${SEQ_TOP + SEQ_BOX_H / 2 + 4}" text-anchor="middle">${esc(n)}</text>`,
    )
  })
  msgs.forEach((m, i) => {
    const y = SEQ_MSG_TOP + i * SEQ_MSG_STEP
    const x1 = laneX(names.indexOf(m.from))
    const x2 = laneX(names.indexOf(m.to))
    const cls = m.tone ? `msg ${m.tone}` : 'msg'
    out.push(`  <line class="${cls}" x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" marker-end="url(#ah${m.tone ? '-' + m.tone : ''}-${uid})"/>`)
    out.push(
      `  <text x="${(x1 + x2) / 2}" y="${y - 6}" text-anchor="middle">${esc(m.text)}</text>`,
    )
  })
  out.push('</svg>')
  return out.join('\n')
}

export function renderDiagram(d: Diagram, uid = 'x'): string {
  if (Array.isArray(d)) return d.join('\n')
  if (typeof d === 'object' && d !== null) {
    if (isStates(d)) return statesHtml(d)
    if (isTree(d)) return treeHtml(d)
    if (isSeq(d)) return seqSvg(d, uid)
    bad('diagram: kind must be states, seq, or tree')
  }
  bad('diagram: expected an object or a legacy array of html lines')
}
