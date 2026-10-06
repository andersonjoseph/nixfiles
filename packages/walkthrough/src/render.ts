import { commitMeta, diffFor, fileAt, numstat, type Numstat } from './git'
import { parseUnified, selectHunks, type Row } from './diff'
import { tokenizeLines, tokenLineHtml, type LineTokens } from './highlight'
import { renderDiagram, type Diagram } from './diagram'
import { esc, escHtml5 } from './html'

export type Category =
  | 'ui'
  | 'api'
  | 'core'
  | 'data'
  | 'cli'
  | 'security'
  | 'tests'
  | 'docs'
  | 'examples'
  | 'deps'
  | 'build'
  | 'scripts'
  | 'config'
  | 'i18n'
  | 'assets'
  | 'other'

export interface Group {
  key: string
  label: string
  category: Category
  summary?: string
  critical?: boolean
}

export interface LineNote {
  line: number
  side: 'additions' | 'deletions'
  text: string
  critical?: boolean
}

export interface CodeRef {
  path: string
  from: number
  to: number
  note?: string[]
  notes?: LineNote[]
}

export interface Item {
  title?: string
  group?: string
  ps?: string[]
  diagram?: Diagram
  code?: CodeRef
}

export interface CommitEntry {
  sha: string
  touches?: string | null
  why?: string[][]
  groups?: Group[]
  items?: Item[]
}

export interface Sidecar {
  schemaVersion?: number
  repo?: string
  subtitle?: string
  range?: string
  fingerprint?: string
  overallSummary?: string[]
  commits: CommitEntry[]
}

function noteHtml(note: string[]): string {
  return esc(note.join('\n'))
    .split('\n')
    .map((line, i) => (i === 0 ? line : `    ${line}`))
    .join('\n')
}

function lineNoteHtml(note: LineNote): string {
  const badge = note.critical ? '<span class="crit">critical</span> ' : ''
  return `<div class="linenote${note.critical ? ' ncrit' : ''}">${badge}${esc(note.text)}</div>`
}

function rowHtml(row: Row, newTokens: LineTokens | null, oldTokens: LineTokens | null): string {
  if (row.kind === 'add') {
    const code = tokenLineHtml(newTokens, row.new) ?? esc(row.text)
    return `<div class="cl add"><span class="g old"></span><span class="g new">${row.new}</span><span class="sg">+</span>${code}</div>`
  }
  if (row.kind === 'del') {
    const code = tokenLineHtml(oldTokens, row.old) ?? esc(row.text)
    return `<div class="cl del"><span class="g old">${row.old}</span><span class="g new"></span><span class="sg">-</span>${code}</div>`
  }
  const code = tokenLineHtml(newTokens, row.new) ?? esc(row.text)
  return `<div class="cl"><span class="g old">${row.old}</span><span class="g new">${row.new}</span><span class="sg"></span>${code}</div>`
}

function notesForRow(notes: LineNote[] | undefined, row: Row): string {
  if (!notes || notes.length === 0) return ''
  const hits = notes.filter((n) =>
    n.side === 'deletions' ? row.kind === 'del' && row.old === n.line : row.kind !== 'del' && row.new === n.line,
  )
  return hits.map(lineNoteHtml).join('\n')
}

const GAP_ROW = '<div class="cl gap">&#183;&#183;&#183;</div>'

async function snapshotRows(sha: string, code: CodeRef, cwd: string): Promise<string> {
  let src: string
  try {
    src = fileAt(sha, code.path, cwd)
  } catch {
    return `<div class="cl gap">file not present at ${esc(sha)}</div>`
  }
  const tokens = await tokenizeLines(src, code.path)
  const rows = src
    .split('\n')
    .slice(code.from - 1, code.to)
    .map((line, i) => {
      const n = code.from + i
      const body = tokenLineHtml(tokens, n) ?? esc(line)
      const notes = (code.notes ?? [])
        .filter((nt) => nt.side === 'additions' && nt.line === n)
        .map(lineNoteHtml)
        .join('\n')
      const rowHtmlLine = `<div class="cl"><span class="ln">${n}</span>${body}</div>`
      return notes ? `${rowHtmlLine}\n${notes}` : rowHtmlLine
    })
    .join('\n')
  return rows
}

async function diffRows(sha: string, code: CodeRef, cwd: string): Promise<string> {
  const hunks = selectHunks(parseUnified(diffFor(sha, code.path, cwd)), code.from, code.to)
  if (hunks.length === 0) return ''
  const hasDel = hunks.some((h) => h.rows.some((r) => r.kind === 'del'))
  const newTokens = await tokenizeLines(fileAt(sha, code.path, cwd), code.path).catch(() => null)
  const oldTokens = hasDel
    ? await tokenizeLines(fileAt(`${sha}^`, code.path, cwd), code.path).catch(() => null)
    : null
  const groups = hunks.map((h) =>
    h.rows
      .map((r) => {
        const row = rowHtml(r, newTokens, oldTokens)
        const notes = notesForRow(code.notes, r)
        return notes ? `${row}\n${notes}` : row
      })
      .join('\n'),
  )
  return groups.join(`\n${GAP_ROW}\n`)
}

async function codeBlockHtml(sha: string, code: CodeRef, cwd: string, anchor: string): Promise<string> {
  let rows = await diffRows(sha, code, cwd)
  let verb = 'diff'
  if (!rows) {
    rows = await snapshotRows(sha, code, cwd)
    verb = 'real code'
  }
  const out = [`    <pre class="code">${rows}</pre>`]
  if (code.note && code.note.length > 0) {
    out.push(`    <p class="ctx">${noteHtml(code.note)}</p>`)
  }
  return [`  <details id="${anchor}">`, `    <summary>show ${verb}: ${esc(code.path)}:${code.from}-${code.to}</summary>`, ...out, `  </details>`].join('\n')
}

async function itemBodyHtml(item: Item, sha: string, sec: number, idx: number, cwd: string): Promise<string> {
  const out: string[] = []
  const ps = item.ps ?? []
  const uid = `s${sec}i${idx}`
  let diagramHtml = ''
  if (item.diagram !== undefined) {
    try {
      diagramHtml = renderDiagram(item.diagram, uid)
    } catch (err) {
      throw new Error(`${sha} item ${idx}: ${(err as Error).message}`)
    }
  }
  if (item.title) out.push(`  <h3>${esc(item.title)}</h3>`)
  if (diagramHtml && ps.length > 0) {
    const n = uid
    out.push(
      `  <div class="views">`,
      `    <input class="d" type="radio" name="${n}" id="${n}d" checked>`,
      `    <input class="p" type="radio" name="${n}" id="${n}p">`,
      `    <label class="d" for="${n}d">diagram</label>`,
      `    <label class="p" for="${n}p">pseudocode</label>`,
      `    <div class="view d">`,
      indent6(diagramHtml),
      `    </div>`,
      `    <div class="view p"><pre class="ps">${esc(ps.join('\n'))}</pre></div>`,
      `  </div>`,
    )
  } else if (ps.length > 0) {
    out.push(`  <pre class="ps">${esc(ps.join('\n'))}</pre>`)
  } else if (diagramHtml) {
    out.push(`  <div class="diagram">`, indent6(diagramHtml), `  </div>`)
  }
  if (item.code) {
    out.push(await codeBlockHtml(sha, item.code, cwd, `c${sec}-${idx}`))
  }
  return out.join('\n')
}

function indent6(html: string): string {
  return html
    .split('\n')
    .map((l) => (l ? `      ${l}` : l))
    .join('\n')
}

function whyHtml(commit: CommitEntry): string {
  return (commit.why ?? [])
    .map((para) => `<p>${escHtml5(para.join('\n'))}</p>`)
    .join('\n')
    .split('\n')
    .map((line) => `  ${line}`)
    .join('\n')
}

function chipHtml(category: Category): string {
  return `<span class="chip ${category}">${category}</span>`
}

async function sectionHtml(commit: CommitEntry, sec: number, cwd: string): Promise<string> {
  const sha = commit.sha
  const meta = commitMeta(sha, cwd)
  const stats: Numstat = numstat(sha, cwd)
  const touches = commit.touches || ''
  const chips = (commit.groups ?? []).map((g) => chipHtml(g.category)).join(' ')
  const out: string[] = []
  out.push(`<section class="commit" id="sec${sec}">`)
  out.push(`  <h2>${sec}. ${esc(meta.title)} <code>${esc(sha)}</code></h2>`)
  const metaLine = `${esc(meta.date)}, ${stats.files} files, +${stats.add} -${stats.rem}`
  const touchesPart = touches ? ` · touches: ${esc(touches)}` : ''
  const chipsPart = chips ? ` <span class="cat">${chips}</span>` : ''
  out.push(`  <p class="meta">${metaLine}${touchesPart}${chipsPart}</p>`)
  if (meta.body) out.push(`  <blockquote class="msg">${esc(meta.body)}</blockquote>`)
  if (!commit.why || commit.why.length === 0) {
    out.push(`  <p class="todo">not curated yet</p>`)
  } else {
    out.push(whyHtml(commit))
  }
  for (const [i, item] of (commit.items ?? []).entries()) {
    out.push(await itemBodyHtml(item, sha, sec, i + 1, cwd))
  }
  out.push(`</section>`)
  return out.join('\n')
}

interface ScopeBucket {
  key: string
  label: string
  category: Category
  summary?: string
  critical?: boolean
  entries: { sec: number; idx: number; sha: string; item: Item }[]
}

function scopeBuckets(sidecar: Sidecar): ScopeBucket[] {
  const byKey = new Map<string, ScopeBucket>()
  sidecar.commits.forEach((c, i) => {
    for (const g of c.groups ?? []) {
      if (!byKey.has(g.key)) {
        byKey.set(g.key, { ...g, entries: [] })
      }
    }
    for (const [j, item] of (c.items ?? []).entries()) {
      const key = item.group && byKey.has(item.group) ? item.group : '_ungrouped'
      if (!byKey.has(key)) {
        byKey.set(key, {
          key,
          label: 'ungrouped',
          category: 'other',
          entries: [],
        })
      }
      byKey.get(key)!.entries.push({ sec: i + 1, idx: j + 1, sha: c.sha, item })
    }
  })
  const buckets = [...byKey.values()].filter((b) => b.entries.length > 0)
  buckets.sort((a, b) => (a.key === '_ungrouped' ? 1 : b.key === '_ungrouped' ? -1 : 0))
  return buckets
}

function scopeHtml(sidecar: Sidecar): string {
  return scopeBuckets(sidecar)
    .map((b) => {
      const out: string[] = []
      const crit = b.critical ? ' <span class="crit">critical</span>' : ''
      out.push(`<section class="group" id="g-${escHtml5(b.key)}">`)
      out.push(`  <h2>${chipHtml(b.category)} ${esc(b.label)}${crit}</h2>`)
      if (b.summary) out.push(`  <p>${esc(b.summary)}</p>`)
      const secs = [...new Set(b.entries.map((e) => e.sec))]
      const itemWord = b.entries.length === 1 ? 'item' : 'items'
      out.push(`  <details>`)
      out.push(`    <summary>${b.entries.length} ${itemWord} · from commit${secs.length === 1 ? '' : 's'} ${secs.join(', ')}</summary>`)
      for (const e of b.entries) {
        out.push(`    <div class="gitem">`)
        out.push(`      <p class="gsrc"><a href="#sec${e.sec}">commit ${e.sec} · ${esc(e.sha)}</a></p>`)
        const body = syncItemBody(e.item, e.sec, e.idx)
        out.push(body)
        out.push(`    </div>`)
      }
      out.push(`  </details>`)
      out.push(`</section>`)
      return out.join('\n')
    })
    .join('\n')
}

function syncItemBody(item: Item, sec: number, idx: number): string {
  const out: string[] = []
  if (item.title) out.push(`      <h3>${esc(item.title)}</h3>`)
  if (item.ps?.length) out.push(`      <pre class="ps">${esc(item.ps.join('\n'))}</pre>`)
  if (item.diagram !== undefined) {
    let html: string
    try {
      html = renderDiagram(item.diagram, `g${sec}i${idx}`)
    } catch (err) {
      throw new Error(`scope view, commit ${sec} item ${idx}: ${(err as Error).message}`)
    }
    out.push(`      <div class="diagram">`, indent6(html), `      </div>`)
  }
  if (item.code) {
    out.push(`      <p class="gcode"><a href="#c${sec}-${idx}">see the code in commit ${sec}</a></p>`)
  }
  return out.join('\n')
}

const PAGE_CSS = `  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #0d1117; color: #c9d1d9; font: 16px/1.6 system-ui, sans-serif; }
  .layout { display: grid; grid-template-columns: 230px minmax(0, 60rem); gap: 2rem; max-width: 82rem; margin: 0 auto; padding: 0 1rem 6rem; }
  header.page { grid-column: 1 / -1; border-bottom: 1px solid #30363d; padding: 2rem 0 1rem; }
  header.page h1 { margin: 0 0 .25rem; font-size: 1.4rem; }
  header.page p { margin: .2rem 0; color: #8b949e; }
  .progresswrap { margin: .8rem 0 .2rem; }
  .bar { height: 6px; border-radius: 999px; background: #21262d; overflow: hidden; max-width: 28rem; }
  .bar i { display: block; height: 100%; background: linear-gradient(90deg,#238636,#3fb950); }
  .summary { margin: 1rem 0 0; padding: .6rem .9rem; border-left: 3px solid #388bfd; background: #161b22; max-width: 46rem; }
  .summary p { margin: .3rem 0; color: #c9d1d9; }
  .viewtoggle { display: inline-flex; border: 1px solid #30363d; border-radius: 8px; overflow: hidden; margin-left: 1rem; vertical-align: middle; }
  .viewtoggle button { background: #0d1117; color: #8b949e; border: none; padding: .35rem .9rem; cursor: pointer; font: .82rem/1 ui-monospace, monospace; }
  .viewtoggle button.on { background: #388bfd; color: #0d1117; }
  nav.toc { position: sticky; top: 1rem; align-self: start; font-size: .88rem; }
  nav.toc h4 { margin: 0 0 .5rem; font-size: .75rem; letter-spacing: .08em; color: #6e7681; text-transform: uppercase; }
  nav.toc a { display: flex; gap: .5rem; align-items: baseline; color: #8b949e; text-decoration: none; padding: .25rem 0; }
  nav.toc a:hover { color: #c9d1d9; }
  nav.toc .dot { width: 8px; height: 8px; border-radius: 50%; background: #3fb950; flex: none; position: relative; top: -1px; }
  nav.toc a.todo .dot { background: #30363d; border: 1px solid #6e7681; }
  nav.toc .keys { margin-top: 1.2rem; color: #6e7681; font: .78rem/1.8 ui-monospace, monospace; }
  nav.toc .keys kbd { border: 1px solid #30363d; border-bottom-width: 2px; border-radius: 4px; padding: 0 .35rem; background: #161b22; }
  section.commit { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem 1.25rem 1.25rem; margin: 1.5rem 0; scroll-margin-top: 1rem; }
  section.group { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem 1.25rem; margin: 1.2rem 0; scroll-margin-top: 1rem; }
  section.group > h2 { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }
  section.group > p { color: #8b949e; max-width: 44rem; }
  h2 { font-size: 1.1rem; margin: .2rem 0 .4rem; }
  h2 code { color: #8b949e; font-size: .85rem; font-weight: normal; }
  p.meta { color: #8b949e; font-size: .85rem; margin: .2rem 0 .8rem; }
  blockquote.msg { margin: .5rem 0; padding: .5rem .9rem; border-left: 3px solid #388bfd; background: #0d1117; color: #8b949e; white-space: pre-wrap; }
  h3 { font-size: .95rem; margin: 1rem 0 .3rem; color: #e6edf3; }
  .why p { max-width: 44rem; }
  pre { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: .8rem 1rem; overflow-x: auto; font: 13px/1.5 ui-monospace, monospace; }
  pre.ps { border-color: #2ea04366; }
  details { margin: .4rem 0 1rem; scroll-margin-top: 1rem; }
  @keyframes flashfade { from { outline: 2px solid #388bfd; outline-offset: 4px; } to { outline: 2px solid transparent; outline-offset: 4px; } }
  .flash { animation: flashfade 1.2s ease-out 1; }
  summary { cursor: pointer; color: #58a6ff; font-family: ui-monospace, monospace; font-size: .85rem; }
  summary:hover { color: #79c0ff; }
  p.ctx { color: #8b949e; font-size: .9rem; margin: .4rem 0 0; }
  p.todo { color: #8b949e; font-style: italic; }
  .chip { display: inline-block; border-radius: 999px; padding: 0 .6rem; font: .75rem/1.6 ui-monospace, monospace; border: 1px solid; }
  .chip.ui { color: #d2a8ff; border-color: #a371f7; }
  .chip.api { color: #e3b341; border-color: #bb8009; }
  .chip.core { color: #79c0ff; border-color: #58a6ff; }
  .chip.data { color: #7ee787; border-color: #3fb950; }
  .chip.cli { color: #ffa657; border-color: #d29922; }
  .chip.security { color: #ffa198; border-color: #f85149; }
  .chip.tests { color: #ff9492; border-color: #f85149; }
  .chip.docs { color: #c4d1d9; border-color: #6e7681; }
  .chip.examples { color: #79c0ff; border-color: #1f6feb; }
  .chip.deps { color: #c4d1d9; border-color: #6e7681; }
  .chip.build { color: #d2a8ff; border-color: #8250df; }
  .chip.scripts { color: #ffa657; border-color: #bb8009; }
  .chip.config { color: #79c0ff; border-color: #388bfd; }
  .chip.i18n { color: #e3b341; border-color: #9e6a03; }
  .chip.assets { color: #c4d1d9; border-color: #6e7681; }
  .chip.other { color: #c4d1d9; border-color: #6e7681; }
  .crit { display: inline-block; background: #da3633; color: #fff; border-radius: 4px; padding: 0 .45rem; font: .72rem/1.6 ui-monospace, monospace; margin-left: .5rem; }
  .views { margin: .3rem 0 .6rem; }
  .views > input { position: absolute; opacity: 0; pointer-events: none; }
  .views > label { display: inline-block; cursor: pointer; font: .78rem ui-monospace, monospace; color: #8b949e; border: 1px solid #30363d; border-bottom: none; border-radius: 6px 6px 0 0; padding: .2rem .7rem; margin: 0 .2rem 0 0; position: relative; top: 1px; }
  .views > label:hover { color: #c9d1d9; }
  .views > input:checked ~ label { color: #58a6ff; background: #0d1117; border-color: #388bfd; }
  .views > .view { display: none; border: 1px solid #30363d; border-radius: 0 6px 6px 6px; background: #0d1117; padding: .8rem 1rem; overflow-x: auto; }
  .views > input.d:checked ~ div.view.d { display: block; }
  .views > input.p:checked ~ div.view.p { display: block; }
  .views pre.ps { border: none; padding: 0; background: none; }
  ul.tree { list-style: none; margin: 0; padding: 0; font: 13px/1.8 ui-monospace, monospace; }
  ul.tree ul { padding-left: 1.2rem; margin: 0; }
  ul.tree li { position: relative; padding-left: 1rem; }
  ul.tree li::before { content: ""; position: absolute; left: 0; top: 0; bottom: -.1rem; border-left: 1px solid #30363d; }
  ul.tree li::after { content: ""; position: absolute; left: 0; top: .9em; width: .7rem; border-top: 1px solid #30363d; }
  ul.tree li:last-child::before { bottom: auto; height: .9em; }
  ul.tree li.add { color: #3fb950; }
  ul.tree li.del { color: #f85149; }
  .sig { display: inline-block; width: .8rem; font-weight: bold; }
  .dim { color: #8b949e; }
  .states > div { margin: .35rem 0; font-size: .9rem; }
  .states > div.add::before { content: "+ "; color: #3fb950; font-family: ui-monospace, monospace; }
  .states > div.del::before { content: "- "; color: #f85149; font-family: ui-monospace, monospace; }
  .st { display: inline-block; border: 1px solid #30363d; border-radius: 999px; padding: 0 .55rem; font: .8rem/1.5 ui-monospace, monospace; color: #c9d1d9; }
  .st-ok { border-color: #3fb950; color: #3fb950; }
  .st-x { border-color: #f85149; color: #f85149; }
  .ar { color: #8b949e; margin: 0 .35rem; }
  svg.seq { width: 100%; height: auto; display: block; }
  svg.seq text { font: 11px ui-monospace, monospace; fill: #c9d1d9; }
  svg.seq .lane { stroke: #30363d; stroke-dasharray: 4 4; }
  svg.seq .actor { fill: #161b22; stroke: #388bfd; }
  svg.seq .msg { stroke: #388bfd; stroke-width: 1.5; }
  svg.seq .bad { stroke: #f85149; }
  svg.seq .good { stroke: #3fb950; }
  pre.code { white-space: normal; padding: .6rem 0; }
  pre.code div.cl { white-space: pre; padding: 0 1rem; }
  pre.code .ln { display: inline-block; width: 3.4rem; color: #6e7681; text-align: right; padding-right: .9rem; user-select: none; }
  pre.code .g { display: inline-block; width: 2.4rem; color: #6e7681; text-align: right; padding-right: .5rem; user-select: none; }
  pre.code .sg { display: inline-block; width: .9rem; user-select: none; }
  div.cl.add { background: rgba(46, 160, 67, .15); }
  div.cl.del { background: rgba(248, 81, 73, .15); }
  div.cl.add .sg { color: #3fb950; }
  div.cl.del .sg { color: #f85149; }
  div.cl.add .g.new { color: #3fb950; }
  div.cl.del .g.old { color: #f85149; }
  div.cl.gap { color: #6e7681; text-align: center; user-select: none; }
  div.linenote { white-space: normal; background: rgba(187,128,9,.1); border-left: 3px solid #d29922; margin: 2px 0; padding: .3rem 1rem .3rem .8rem; font-size: 12.5px; color: #e3b341; }
  div.linenote.ncrit { background: rgba(248,81,73,.1); border-left-color: #f85149; color: #ffa198; }
  div.linenote .crit { margin: 0 .4rem 0 0; }
  .gitem { margin: .6rem 0; }
  p.gsrc { font: .8rem/1.6 ui-monospace, monospace; }
  p.gsrc a, p.gcode a { color: #58a6ff; }
  p.gcode { font: .8rem/1.6 ui-monospace, monospace; color: #6e7681; }
  body[data-view="scope"] .commits { display: none; }
  body:not([data-view="scope"]) .scopes { display: none; }
  footer.page { grid-column: 1 / -1; color: #6e7681; font-size: .8rem; border-top: 1px solid #30363d; padding-top: 1rem; }
  @media (max-width: 900px) {
    .layout { grid-template-columns: 1fr; }
    nav.toc { position: static; }
    nav.toc div.links { display: flex; flex-wrap: wrap; gap: .8rem; }
    nav.toc .keys { display: none; }
  }
`

const PAGE_JS = `
  var body = document.body
  var bS = document.getElementById('btn-commits')
  var bV = document.getElementById('btn-scope')
  function setView(v) {
    body.dataset.view = v
    bS.classList.toggle('on', v === 'commits')
    bV.classList.toggle('on', v === 'scope')
    cursor = 0
    try { localStorage.setItem('wt-view', v) } catch (e) {}
  }
  bS.onclick = function () { setView('commits') }
  bV.onclick = function () { setView('scope') }
  try {
    var saved = localStorage.getItem('wt-view')
    if (saved === 'commits' || saved === 'scope') setView(saved)
  } catch (e) {}
  function sections() {
    var sel = body.dataset.view === 'scope' ? 'section.group' : 'section.commit'
    return Array.prototype.slice.call(document.querySelectorAll(sel))
  }
  var cursor = 0
  document.addEventListener('keydown', function (e) {
    if (e.target !== document.body) return
    if (e.key === 't') setView(body.dataset.view === 'commits' ? 'scope' : 'commits')
    if (e.key === 'n') { cursor = Math.min(cursor + 1, sections().length - 1); sections()[cursor].scrollIntoView({behavior:'smooth'}) }
    if (e.key === 'p') { cursor = Math.max(cursor - 1, 0); sections()[cursor].scrollIntoView({behavior:'smooth'}) }
  })
  document.addEventListener('click', function (e) {
    var t = e.target
    var a = t && t.closest ? t.closest('a[href^="#"]') : null
    if (!a) return
    var id = a.getAttribute('href').slice(1)
    var el = document.getElementById(id)
    if (!el) return
    e.preventDefault()
    if (el.closest('.scopes')) {
      if (body.dataset.view !== 'scope') setView('scope')
    } else if (body.dataset.view !== 'commits') {
      setView('commits')
    }
    var d = el.closest('details')
    while (d) { d.open = true; d = d.parentElement ? d.parentElement.closest('details') : null }
    requestAnimationFrame(function () {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' })
      el.classList.remove('flash')
      void el.offsetWidth
      el.classList.add('flash')
    })
  })
`

export async function renderPage(root: string, sidecar: Sidecar): Promise<string> {
  const repo = sidecar.repo || root.split('/').pop() || ''
  const sub = sidecar.subtitle || ''
  const total = sidecar.commits.length
  const curated = sidecar.commits.filter((c) => (c.why ?? []).length > 0).length
  const pct = total === 0 ? 100 : Math.round((curated / total) * 100)
  const buckets = scopeBuckets(sidecar)

  const out: string[] = []
  out.push(`<!doctype html>`)
  out.push(`<html lang="en">`)
  out.push(`<head>`)
  out.push(`<meta charset="utf-8">`)
  out.push(`<meta name="viewport" content="width=device-width, initial-scale=1">`)
  out.push(`<title>commit walk: ${esc(repo)}</title>`)
  out.push(`<style>`)
  out.push(PAGE_CSS)
  out.push(`</style>`)
  out.push(`</head>`)
  out.push(`<body data-view="commits">`)
  out.push(`<div class="layout">`)
  out.push(`<header class="page">`)
  out.push(
    `  <h1>commit walk: ${esc(repo)} <span class="viewtoggle"><button id="btn-commits" class="on" type="button">commits</button><button id="btn-scope" type="button">scope</button></span></h1>`,
  )
  const subPart = sub ? `${esc(sub)}, ` : ''
  out.push(`  <p>${subPart}${esc(sidecar.range || '')}, ${total} commits, oldest first</p>`)
  out.push(`  <div class="progresswrap"><div class="bar"><i style="width:${pct}%"></i></div><p>${curated} of ${total} curated</p></div>`)
  if (sidecar.overallSummary?.length) {
    out.push(`  <div class="summary">`)
    for (const para of sidecar.overallSummary) out.push(`    <p>${escHtml5(para)}</p>`)
    out.push(`  </div>`)
  }
  out.push(`</header>`)

  out.push(`<nav class="toc">`)
  out.push(`  <h4>commits</h4>`)
  out.push(`  <div class="links">`)
  sidecar.commits.forEach((c, i) => {
    const meta = commitMeta(c.sha, root)
    const todo = !c.why || c.why.length === 0 ? ' class="todo"' : ''
    out.push(`    <a href="#sec${i + 1}"${todo}><span class="dot"></span>${i + 1}. ${esc(meta.title)}</a>`)
  })
  out.push(`  </div>`)
  if (buckets.length > 0) {
    out.push(`  <h4 style="margin-top:1.2rem">scopes</h4>`)
    out.push(`  <div class="links">`)
    for (const b of buckets) {
      out.push(`    <a href="#g-${escHtml5(b.key)}">${chipHtml(b.category)} ${esc(b.label)}</a>`)
    }
    out.push(`  </div>`)
  }
  out.push(`  <p class="keys"><kbd>n</kbd> <kbd>p</kbd> jump sections<br><kbd>t</kbd> toggles view</p>`)
  out.push(`</nav>`)

  out.push(`<main>`)
  out.push(`<div class="commits">`)
  for (const [i, c] of sidecar.commits.entries()) {
    out.push(await sectionHtml(c, i + 1, root))
  }
  out.push(`</div>`)
  out.push(`<div class="scopes">`)
  out.push(scopeHtml(sidecar))
  out.push(`</div>`)
  out.push(`</main>`)
  out.push(`<footer class="page">one file · offline · deterministic bytes</footer>`)
  out.push(`</div>`)
  out.push(`<script>${PAGE_JS}</script>`)
  out.push(`</body>`)
  out.push(`</html>`)
  return out.join('\n') + '\n'
}
