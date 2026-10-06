import { execFileSync } from 'node:child_process'

const MAX_BUFFER = 1 << 26

export function git(args: string[], cwd: string): string {
  return execFileSync('git', args, { encoding: 'utf8', maxBuffer: MAX_BUFFER, cwd })
}

export function repoRoot(): string {
  return execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim()
}

export function revList(range: string, cwd: string): string[] {
  return git(['rev-list', '--no-merges', '--reverse', range], cwd)
    .split('\n')
    .filter(Boolean)
}

export function shortSha(sha: string, cwd: string): string {
  return git(['rev-parse', '--short=7', sha], cwd).trim()
}

export interface CommitMeta {
  title: string
  date: string
  body: string
}

export function commitMeta(sha: string, cwd: string): CommitMeta {
  const out = git(['log', '-1', '--format=%s%x00%as%x00%b', sha], cwd)
  const [title = '', date = '', ...bodyParts] = out.split('\0')
  return { title: title.replace(/\n$/, ''), date, body: bodyParts.join('\0').replace(/\n$/, '') }
}

export interface Numstat {
  files: number
  add: number
  rem: number
}

export function numstat(sha: string, cwd: string): Numstat {
  const out = git(['show', '--numstat', '--format=', sha], cwd)
  let files = 0
  let add = 0
  let rem = 0
  for (const line of out.split('\n')) {
    if (!line.trim()) continue
    const [a = '-', r = '-'] = line.split('\t')
    files++
    add += a === '-' ? 0 : Number(a)
    rem += r === '-' ? 0 : Number(r)
  }
  return { files, add, rem }
}

export function fileAt(sha: string, path: string, cwd: string): string {
  return git(['show', `${sha}:${path}`], cwd)
}

export function diffFor(sha: string, path: string, cwd: string): string {
  try {
    return execFileSync(
      'git',
      ['diff', '--no-color', '--unified=3', `${sha}^`, sha, '--', path],
      { encoding: 'utf8', maxBuffer: MAX_BUFFER, cwd, stdio: ['ignore', 'pipe', 'ignore'] },
    )
  } catch {
    return ''
  }
}
