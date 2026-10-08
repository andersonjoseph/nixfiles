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

const PAGE_CSS = `  :root {
    color-scheme: dark;
    --bg: #111111;
    --surface: #121212;
    --popover: #1e1e24;
    --fg: #e5e5e5;
    --muted: #9a9a9a;
    --faint: #6e6e6e;
    --border: rgb(153 153 153 / .13);
    --border-strong: rgb(153 153 153 / .25);
    --accent: #5b9544;
    --accent-bright: #6fae54;
    --link: #5fc2a4;
    --link-bright: #8adcc4;
    --add: #5b9544;
    --add-bright: #6fae54;
    --del: #f63d68;
    --warn: #fbbf24;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--fg); font: 16px/1.6 ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif; }
  .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, Liberation Mono, Courier New, monospace; }
  .layout { display: grid; grid-template-columns: 230px minmax(0, 60rem); gap: 2rem; max-width: 82rem; margin: 0 auto; padding: 0 1rem 6rem; }
  header.page { grid-column: 1 / -1; border-bottom: 1px solid var(--border); padding: 2rem 0 1rem; }
  header.page h1 { margin: 0 0 .25rem; font-size: 1.4rem; font-weight: 600; letter-spacing: -.025em; }
  header.page p { margin: .2rem 0; color: var(--muted); }
  .progresswrap { margin: .8rem 0 .2rem; }
  .bar { height: 6px; border-radius: 999px; background: var(--popover); overflow: hidden; max-width: 28rem; }
  .bar i { display: block; height: 100%; background: var(--accent); }
  .summary { margin: 1rem 0 0; padding: .6rem .9rem; border-left: 3px solid var(--link); background: var(--surface); max-width: 46rem; }
  .summary p { margin: .3rem 0; color: var(--fg); }
  .viewtoggle { display: inline-flex; border: 1px solid var(--border); border-radius: .5rem; overflow: hidden; margin-left: 1rem; vertical-align: middle; }
  .viewtoggle button { background: transparent; color: var(--muted); border: none; padding: .35rem .9rem; cursor: pointer; font: .82rem/1 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  .viewtoggle button:hover { color: var(--fg); }
  .viewtoggle button.on { background: var(--accent); color: #111111; }
  nav.toc { position: sticky; top: 1rem; align-self: start; font-size: .88rem; }
  nav.toc h4 { margin: 0 0 .5rem; font-size: .75rem; letter-spacing: .08em; color: var(--faint); text-transform: uppercase; }
  nav.toc a { display: flex; gap: .5rem; align-items: baseline; color: var(--muted); text-decoration: none; padding: .25rem 0; }
  nav.toc a:hover { color: var(--fg); }
  nav.toc .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--accent); flex: none; position: relative; top: -1px; }
  nav.toc a.todo .dot { background: transparent; border: 1px solid var(--border-strong); }
  nav.toc .keys { margin-top: 1.2rem; color: var(--faint); font: .78rem/1.8 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  nav.toc .keys kbd { border: 1px solid var(--border-strong); border-bottom-width: 2px; border-radius: 4px; padding: 0 .35rem; background: var(--popover); }
  section.commit, section.group { background: var(--surface); border: 1px solid var(--border); border-radius: .5rem; padding: 1rem 1.25rem 1.25rem; margin: 1.5rem 0; scroll-margin-top: 1rem; }
  section.group { margin: 1.2rem 0; }
  section.group > h2 { display: flex; align-items: center; gap: .6rem; flex-wrap: wrap; }
  section.group > p { color: var(--muted); max-width: 44rem; }
  h2 { font-size: 1.1rem; font-weight: 600; letter-spacing: -.025em; margin: .2rem 0 .4rem; }
  h2 code { color: var(--faint); font-size: .85rem; font-weight: normal; }
  p.meta { color: var(--muted); font-size: .85rem; margin: .2rem 0 .8rem; }
  blockquote.msg { margin: .5rem 0; padding: .5rem .9rem; border-left: 3px solid var(--border-strong); background: var(--bg); color: var(--muted); white-space: pre-wrap; }
  h3 { font-size: .95rem; font-weight: 600; margin: 1rem 0 .3rem; color: var(--fg); }
  .why p { max-width: 44rem; }
  pre { background: var(--bg); border: 1px solid var(--border); border-radius: .375rem; padding: .8rem 1rem; overflow-x: auto; font: 13px/1.5 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  pre.ps { border-color: rgb(91 149 68 / .35); }
  details { margin: .4rem 0 1rem; scroll-margin-top: 1rem; }
  summary { cursor: pointer; color: var(--link); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; font-size: .85rem; }
  summary:hover { color: var(--link-bright); }
  p.ctx { color: var(--muted); font-size: .9rem; margin: .4rem 0 0; }
  p.todo { color: var(--faint); font-style: italic; }
  .chip { display: inline-block; border-radius: 9999px; padding: 0 .6rem; font: .75rem/1.6 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; border: 1px solid; }
  .chip.ui { color: #c7a4f9; background: rgb(199 164 249 / .09); border-color: rgb(199 164 249 / .26); }
  .chip.api { color: #fbbf24; background: rgb(251 191 36 / .09); border-color: rgb(251 191 36 / .26); }
  .chip.core { color: #5fc2a4; background: rgb(95 194 164 / .09); border-color: rgb(95 194 164 / .26); }
  .chip.data { color: #8fce7f; background: rgb(143 206 127 / .09); border-color: rgb(143 206 127 / .26); }
  .chip.cli { color: #fb923c; background: rgb(251 146 60 / .09); border-color: rgb(251 146 60 / .26); }
  .chip.security { color: #f63d68; background: rgb(246 61 104 / .09); border-color: rgb(246 61 104 / .26); }
  .chip.tests { color: #f8a5a5; background: rgb(248 165 165 / .09); border-color: rgb(248 165 165 / .26); }
  .chip.docs { color: #c9c9c9; background: rgb(201 201 201 / .09); border-color: rgb(201 201 201 / .26); }
  .chip.examples { color: #8ad0f0; background: rgb(138 208 240 / .09); border-color: rgb(138 208 240 / .26); }
  .chip.deps { color: #bdbdbd; background: rgb(189 189 189 / .09); border-color: rgb(189 189 189 / .26); }
  .chip.build { color: #b8a6e8; background: rgb(184 166 232 / .09); border-color: rgb(184 166 232 / .26); }
  .chip.scripts { color: #f0b17f; background: rgb(240 177 127 / .09); border-color: rgb(240 177 127 / .26); }
  .chip.config { color: #9fc3e8; background: rgb(159 195 232 / .09); border-color: rgb(159 195 232 / .26); }
  .chip.i18n { color: #e8c98f; background: rgb(232 201 143 / .09); border-color: rgb(232 201 143 / .26); }
  .chip.assets { color: #c9c9c9; background: rgb(201 201 201 / .09); border-color: rgb(201 201 201 / .26); }
  .chip.other { color: #c9c9c9; background: rgb(201 201 201 / .09); border-color: rgb(201 201 201 / .26); }
  .crit { display: inline-block; background: var(--del); color: #fff; border-radius: 4px; padding: 0 .45rem; font: .72rem/1.6 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; margin-left: .5rem; }
  .views { margin: .3rem 0 .6rem; }
  .views > input { position: absolute; opacity: 0; pointer-events: none; }
  .views > label { display: inline-block; cursor: pointer; font: .78rem ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; color: var(--muted); border: 1px solid var(--border); border-bottom: none; border-radius: .375rem .375rem 0 0; padding: .2rem .7rem; margin: 0 .2rem 0 0; position: relative; top: 1px; }
  .views > label:hover { color: var(--fg); }
  .views > input:checked ~ label { color: var(--link); background: var(--bg); border-color: rgb(95 194 164 / .4); }
  .views > .view { display: none; border: 1px solid var(--border); border-radius: 0 .375rem .375rem .375rem; background: var(--bg); padding: .8rem 1rem; overflow-x: auto; }
  .views > input.d:checked ~ div.view.d { display: block; }
  .views > input.p:checked ~ div.view.p { display: block; }
  .views pre.ps { border: none; padding: 0; background: none; }
  ul.tree { list-style: none; margin: 0; padding: 0; font: 13px/1.8 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  ul.tree ul { padding-left: 1.2rem; margin: 0; }
  ul.tree li { position: relative; padding-left: 1rem; }
  ul.tree li::before { content: ""; position: absolute; left: 0; top: 0; bottom: -.1rem; border-left: 1px solid var(--border-strong); }
  ul.tree li::after { content: ""; position: absolute; left: 0; top: .9em; width: .7rem; border-top: 1px solid var(--border-strong); }
  ul.tree li:last-child::before { bottom: auto; height: .9em; }
  ul.tree li.add { color: var(--add-bright); }
  ul.tree li.del { color: var(--del); }
  .sig { display: inline-block; width: .8rem; font-weight: bold; }
  .dim { color: var(--muted); }
  .states > div { margin: .35rem 0; font-size: .9rem; }
  .states > div.add::before { content: "+ "; color: var(--add-bright); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  .states > div.del::before { content: "- "; color: var(--del); font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  .st { display: inline-block; border: 1px solid var(--border-strong); border-radius: 999px; padding: 0 .55rem; font: .8rem/1.5 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; color: var(--fg); }
  .st-ok { border-color: rgb(111 174 84 / .5); color: var(--add-bright); }
  .st-x { border-color: rgb(246 61 104 / .5); color: var(--del); }
  .ar { color: var(--muted); margin: 0 .35rem; }
  svg.seq { width: 100%; height: auto; display: block; }
  svg.seq text { font: 11px ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; fill: var(--fg); }
  svg.seq .lane { stroke: var(--border-strong); stroke-dasharray: 4 4; }
  svg.seq .actor { fill: var(--popover); stroke: var(--link); }
  svg.seq .msg { stroke: var(--link); stroke-width: 1.5; }
  svg.seq .bad { stroke: var(--del); }
  svg.seq .good { stroke: var(--add-bright); }
  pre.code { white-space: normal; padding: .6rem 0; }
  pre.code div.cl { white-space: pre; padding: 0 1rem; }
  pre.code .ln { display: inline-block; width: 3.4rem; color: var(--faint); text-align: right; padding-right: .9rem; user-select: none; }
  pre.code .g { display: inline-block; width: 2.4rem; color: var(--faint); text-align: right; padding-right: .5rem; user-select: none; }
  pre.code .sg { display: inline-block; width: .9rem; user-select: none; }
  div.cl.add { background: rgb(91 149 68 / .16); }
  div.cl.del { background: rgb(246 61 104 / .14); }
  div.cl.add .sg { color: var(--add-bright); }
  div.cl.del .sg { color: var(--del); }
  div.cl.add .g.new { color: var(--add-bright); }
  div.cl.del .g.old { color: var(--del); }
  div.cl.gap { color: var(--faint); text-align: center; user-select: none; }
  div.linenote { white-space: normal; background: rgb(251 191 36 / .08); border-left: 3px solid var(--warn); margin: 2px 0; padding: .3rem 1rem .3rem .8rem; font-size: 12.5px; color: var(--warn); }
  div.linenote.ncrit { background: rgb(246 61 104 / .09); border-left-color: var(--del); color: #f8849e; }
  div.linenote .crit { margin: 0 .4rem 0 0; }
  .gitem { margin: .6rem 0; }
  p.gsrc { font: .8rem/1.6 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
  p.gsrc a, p.gcode a { color: var(--link); }
  p.gcode { font: .8rem/1.6 ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; color: var(--faint); }
  body[data-view="scope"] .commits { display: none; }
  body:not([data-view="scope"]) .scopes { display: none; }
  footer.page { grid-column: 1 / -1; color: var(--faint); font-size: .8rem; border-top: 1px solid var(--border); padding-top: 1rem; }
  @keyframes flashfade { from { outline: 2px solid var(--link); outline-offset: 4px; } to { outline: 2px solid transparent; outline-offset: 4px; } }
  .flash { animation: flashfade 1.2s ease-out 1; }
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
