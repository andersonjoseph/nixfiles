import { commitMeta, diffFor, fileAt, numstat, type Numstat } from './git'
import { parseUnified, selectHunks, type Row } from './diff'

export interface CodeRef {
  path: string
  from: number
  to: number
  note?: string[]
}

export interface Item {
  title?: string
  ps?: string[]
  diagram?: string[]
  code?: CodeRef
}

export interface CommitEntry {
  sha: string
  touches: string | null
  why: string[][]
  items: Item[]
}

export interface Sidecar {
  repo?: string
  subtitle?: string
  range?: string
  commits: CommitEntry[]
}

export function esc(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

export function escHtml5(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/'/g, '&apos;')
    .replace(/"/g, '&quot;')
}

function numberedCode(sha: string, path: string, from: number, to: number, cwd: string): string {
  const src = fileAt(sha, path, cwd)
  return src
    .split('\n')
    .slice(from - 1, to)
    .map((line, i) => `<div class="cl"><span class="ln">${from + i}</span>${esc(line)}</div>`)
    .join('\n')
}

function rowHtml(row: Row): string {
  if (row.kind === 'add') {
    return `<div class="cl add"><span class="g old"></span><span class="g new">${row.new}</span><span class="sg">+</span>${esc(row.text)}</div>`
  }
  if (row.kind === 'del') {
    return `<div class="cl del"><span class="g old">${row.old}</span><span class="g new"></span><span class="sg">-</span>${esc(row.text)}</div>`
  }
  return `<div class="cl"><span class="g old">${row.old}</span><span class="g new">${row.new}</span><span class="sg"></span>${esc(row.text)}</div>`
}

const GAP_ROW = '<div class="cl gap">&#183;&#183;&#183;</div>'

export function diffRows(sha: string, path: string, from: number, to: number, cwd: string): string {
  const diff = diffFor(sha, path, cwd)
  const hunks = parseUnified(diff)
  const groups = selectHunks(hunks, from, to).map((h) => h.rows.map(rowHtml).join('\n'))
  return groups.join(`\n${GAP_ROW}\n`)
}

export function itemHtml(item: Item, sha: string, sec: number, idx: number, cwd: string): string {
  const out: string[] = []
  const ps = item.ps ?? []
  const diagram = item.diagram ?? []
  if (item.title) out.push(`  <h3>${esc(item.title)}</h3>`)
  if (diagram.length > 0 && ps.length > 0) {
    const n = `s${sec}i${idx}`
    out.push(
      `  <div class="views">`,
      `    <input class="d" type="radio" name="${n}" id="${n}d" checked>`,
      `    <input class="p" type="radio" name="${n}" id="${n}p">`,
      `    <label class="d" for="${n}d">diagram</label>`,
      `    <label class="p" for="${n}p">pseudocode</label>`,
      `    <div class="view d">`,
      diagram.join('\n'),
      `    </div>`,
      `    <div class="view p"><pre class="ps">${esc(ps.join('\n'))}</pre></div>`,
      `  </div>`,
    )
  } else if (ps.length > 0) {
    out.push(`  <pre class="ps">${esc(ps.join('\n'))}</pre>`)
  } else if (diagram.length > 0) {
    out.push(`  <div class="diagram">`, diagram.join('\n'), `  </div>`)
  }
  if (item.code) {
    const { path, from, to, note } = item.code
    let rows = diffRows(sha, path, from, to, cwd)
    const verb = rows ? 'diff' : 'real code'
    if (!rows) rows = numberedCode(sha, path, from, to, cwd)
    out.push(`  <details>`)
    out.push(`    <summary>show ${verb}: ${esc(path)}:${from}-${to}</summary>`)
    out.push(`    <pre class="code">${rows}</pre>`)
    if (note && note.length > 0) {
      out.push(`    <p class="ctx">${noteHtml(note)}</p>`)
    }
    out.push(`  </details>`)
  }
  return out.join('\n')
}

function noteHtml(note: string[]): string {
  return esc(note.join('\n'))
    .split('\n')
    .map((line, i) => (i === 0 ? line : `    ${line}`))
    .join('\n')
}

const PAGE_HEAD = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>commit walk</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; background: #0d1117; color: #c9d1d9; font: 16px/1.6 system-ui, sans-serif; }
  header { border-bottom: 1px solid #30363d; padding: 2rem 0 1rem; }
  header h1 { margin: 0 0 .25rem; font-size: 1.4rem; }
  header p { margin: .2rem 0; color: #8b949e; }
  section.commit { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem 1.25rem 1.25rem; margin: 1.5rem 0; }
  h2 { font-size: 1.1rem; margin: .2rem 0 .4rem; }
  h2 code { color: #8b949e; font-size: .85rem; font-weight: normal; }
  p.meta { color: #8b949e; font-size: .85rem; margin: .2rem 0 .8rem; }
  blockquote.msg { margin: .5rem 0; padding: .5rem .9rem; border-left: 3px solid #388bfd; background: #0d1117; color: #8b949e; white-space: pre-wrap; }
  h3 { font-size: .95rem; margin: 1rem 0 .3rem; color: #e6edf3; }
  pre { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: .8rem 1rem; overflow-x: auto; font: 13px/1.5 ui-monospace, monospace; }
  pre.ps { border-color: #2ea04366; }
  details { margin: .4rem 0 1rem; }
  summary { cursor: pointer; color: #58a6ff; font-family: ui-monospace, monospace; font-size: .85rem; }
  summary:hover { color: #79c0ff; }
  p.ctx { color: #8b949e; font-size: .9rem; margin: .4rem 0 0; }
  p.todo { color: #8b949e; font-style: italic; }
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
  main { display: block; max-width: 60rem; margin: 0 auto; padding: 0 1rem 6rem; }
  pre.code .ln { display: inline-block; width: 3.4rem; color: #6e7681; text-align: right; padding-right: .9rem; user-select: none; }
  pre.code { white-space: normal; }
  pre.code div.cl { white-space: pre; }
  pre.code .g { display: inline-block; width: 2.4rem; color: #6e7681; text-align: right; padding-right: .5rem; user-select: none; }
  pre.code .sg { display: inline-block; width: .9rem; user-select: none; }
  pre.code div.cl.add { background: rgba(46, 160, 67, .15); border-radius: 2px; }
  pre.code div.cl.del { background: rgba(248, 81, 73, .15); border-radius: 2px; }
  pre.code div.cl.add .sg { color: #3fb950; }
  pre.code div.cl.del .sg { color: #f85149; }
  pre.code div.cl.add .g.new { color: #3fb950; }
  pre.code div.cl.del .g.old { color: #f85149; }
  pre.code div.cl.gap { color: #6e7681; text-align: center; user-select: none; }
</style>
</head>
<body>
<main>`

export function whyHtml(commit: CommitEntry): string {
  return (commit.why ?? [])
    .map((para) => `<p>${escHtml5(para.join('\n'))}</p>`)
    .join('\n')
    .split('\n')
    .map((line) => `  ${line}`)
    .join('\n')
}

export function sectionHtml(commit: CommitEntry, sec: number, cwd: string): string {
  const sha = commit.sha
  const meta = commitMeta(sha, cwd)
  const stats: Numstat = numstat(sha, cwd)
  const touches = commit.touches || ''
  const out: string[] = []
  out.push(`<section class="commit" id="sec${sec}">`)
  out.push(`  <h2>${sec}. ${esc(meta.title)} <code>${sha}</code></h2>`)
  if (touches) {
    out.push(
      `  <p class="meta">${meta.date}, ${stats.files} files, +${stats.add} -${stats.rem} · touches: ${esc(touches)}</p>`,
    )
  } else {
    out.push(`  <p class="meta">${meta.date}, ${stats.files} files, +${stats.add} -${stats.rem}</p>`)
  }
  if (meta.body) out.push(`  <blockquote class="msg">${esc(meta.body)}</blockquote>`)
  if (!commit.why || commit.why.length === 0) {
    out.push(`  <p class="todo">not curated yet</p>`)
  } else {
    out.push(whyHtml(commit))
  }
  commit.items?.forEach((item, i) => {
    out.push(itemHtml(item, sha, sec, i + 1, cwd))
  })
  out.push(`</section>`)
  return out.join('\n')
}

export function renderPage(root: string, sidecar: Sidecar): string {
  const repo = sidecar.repo || root.split('/').pop() || ''
  const sub = sidecar.subtitle || ''
  const total = sidecar.commits.length
  const curated = sidecar.commits.filter((c) => (c.why ?? []).length > 0).length
  const out: string[] = [PAGE_HEAD]
  out.push(`<header>`)
  out.push(`  <h1>commit walk: ${esc(repo)}</h1>`)
  if (sub) {
    out.push(`  <p>${esc(sub)}, ${esc(sidecar.range || '')}, ${total} commits, oldest first</p>`)
  } else {
    out.push(`  <p>${esc(sidecar.range || '')}, ${total} commits, oldest first</p>`)
  }
  out.push(`  <p>progress: <strong class="progress">${curated} of ${total}</strong></p>`)
  out.push(`</header>`)
  sidecar.commits.forEach((c, i) => out.push(sectionHtml(c, i + 1, root)))
  out.push(`<!-- sections go here -->`)
  out.push(`</main>`)
  out.push(`</body>`)
  out.push(`</html>`)
  return out.join('\n') + '\n'
}
