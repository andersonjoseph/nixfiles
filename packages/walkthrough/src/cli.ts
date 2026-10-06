import { createHash } from 'node:crypto'
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, join } from 'node:path'
import { git, repoRoot, revList, shortSha } from './git'
import { renderPage, type CommitEntry, type Sidecar } from './render'
import { isV1, migrateV1 } from './migrate'

const USAGE = 'usage: wt init <range> [subtitle] | render <range>'

function sidecarPath(root: string, range: string): string {
  const name = range.replace(/[^A-Za-z0-9]/g, '_') + '.json'
  return join(root, '.opencode', 'walkthroughs', name)
}

function emptyCommit(sha: string): CommitEntry {
  return { sha, touches: null, why: [], items: [] }
}

function fingerprint(range: string, cwd: string): string | undefined {
  try {
    const [a, b] = range.split('..')
    const endpoints =
      a && b
        ? [git(['rev-parse', a], cwd).trim(), git(['rev-parse', b], cwd).trim()]
        : [git(['rev-parse', range], cwd).trim()]
    return createHash('sha256').update(`${endpoints.join('\n')}\n2`).digest('hex')
  } catch {
    return undefined
  }
}

function readSidecar(path: string, range: string, cwd: string): Sidecar {
  const raw: unknown = JSON.parse(readFileSync(path, 'utf8'))
  const sidecar: Sidecar = isV1(raw) ? migrateV1(raw) : (raw as Sidecar)
  sidecar.schemaVersion = 2
  sidecar.fingerprint ??= fingerprint(range, cwd)
  return sidecar
}

function writeSidecar(path: string, sidecar: Sidecar): void {
  writeFileSync(path, JSON.stringify(sidecar, null, 2) + '\n')
}

async function doInit(range: string, subtitle: string): Promise<void> {
  const root = repoRoot()
  const path = sidecarPath(root, range)
  mkdirSync(join(root, '.opencode', 'walkthroughs'), { recursive: true })
  const shas = revList(range, root)
  let sidecar: Sidecar
  if (!existsSync(path)) {
    sidecar = {
      schemaVersion: 2,
      fingerprint: fingerprint(range, root),
      repo: basename(root),
      subtitle,
      range,
      commits: shas.map((s) => emptyCommit(shortSha(s, root))),
    }
  } else {
    sidecar = readSidecar(path, range, root)
    sidecar.repo = sidecar.repo ?? basename(root)
    sidecar.range = range
    if (subtitle) sidecar.subtitle = subtitle
    const known = new Set(sidecar.commits.map((c) => c.sha))
    for (const s of shas) {
      const short = shortSha(s, root)
      if (!known.has(short)) sidecar.commits.push(emptyCommit(short))
    }
  }
  writeSidecar(path, sidecar)
  await doRender(range)
  const uncurated = sidecar.commits.filter((c) => (c.why ?? []).length === 0).map((c) => c.sha)
  console.log(`sidecar: ${path}`)
  if (uncurated.length > 0) console.log(`uncurated: ${uncurated.join(' ')}`)
}

async function doRender(range: string): Promise<void> {
  const root = repoRoot()
  const path = sidecarPath(root, range)
  if (!existsSync(path)) {
    console.error(`no sidecar for range ${range} at ${path}`)
    process.exit(1)
  }
  const sidecar = readSidecar(path, range, root)
  const page = join(root, 'commit-walk.html')
  writeFileSync(page, await renderPage(root, sidecar))
  const total = sidecar.commits.length
  const curated = sidecar.commits.filter((c) => (c.why ?? []).length > 0).length
  console.log(`wrote ${page} (${curated} of ${total} curated)`)
}

async function main(): Promise<void> {
  const [cmd, range, subtitle] = process.argv.slice(2)
  if ((cmd !== 'init' && cmd !== 'render') || !range || (cmd === 'render' && subtitle)) {
    console.error(USAGE)
    process.exit(2)
  }
  if (cmd === 'init') await doInit(range, subtitle ?? '')
  else await doRender(range)
}

void main()
