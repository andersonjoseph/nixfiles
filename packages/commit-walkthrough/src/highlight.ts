import { createHighlighterCore, type HighlighterCore } from 'shiki/core'
import { createJavaScriptRegexEngine } from 'shiki'
import bash from 'shiki/langs/bash.mjs'
import css from 'shiki/langs/css.mjs'
import go from 'shiki/langs/go.mjs'
import javascript from 'shiki/langs/javascript.mjs'
import jsonLang from 'shiki/langs/json.mjs'
import markdown from 'shiki/langs/markdown.mjs'
import nix from 'shiki/langs/nix.mjs'
import python from 'shiki/langs/python.mjs'
import rust from 'shiki/langs/rust.mjs'
import typescript from 'shiki/langs/typescript.mjs'
import yaml from 'shiki/langs/yaml.mjs'
import githubDarkDefault from 'shiki/themes/github-dark-default.mjs'
import { esc } from './html'

const THEME = 'github-dark-default'

const LANG_BY_EXT: Record<string, string> = {
  ts: 'typescript',
  tsx: 'typescript',
  mts: 'typescript',
  js: 'javascript',
  mjs: 'javascript',
  cjs: 'javascript',
  jsx: 'javascript',
  json: 'json',
  jsonc: 'json',
  nix: 'nix',
  sh: 'bash',
  bash: 'bash',
  zsh: 'bash',
  md: 'markdown',
  markdown: 'markdown',
  css: 'css',
  yaml: 'yaml',
  yml: 'yaml',
  go: 'go',
  py: 'python',
  rs: 'rust',
}

const TOKENIZED_LANGS = [
  typescript,
  javascript,
  jsonLang,
  nix,
  bash,
  markdown,
  css,
  yaml,
  go,
  python,
  rust,
]

export interface Token {
  content: string
  color: string
  fontStyle: number
}

export type LineTokens = Token[][]

let highlighter: Promise<HighlighterCore> | null = null

function getHighlighter(): Promise<HighlighterCore> {
  highlighter ??= createHighlighterCore({
    langs: TOKENIZED_LANGS,
    themes: [githubDarkDefault],
    engine: createJavaScriptRegexEngine(),
  })
  return highlighter
}

export async function tokenizeLines(code: string, path: string): Promise<LineTokens | null> {
  const ext = path.includes('.') ? (path.split('.').pop() ?? '') : ''
  const lang = LANG_BY_EXT[ext]
  if (!lang) return null
  const hl = await getHighlighter()
  return hl.codeToTokensBase(code, { lang, theme: THEME }) as unknown as LineTokens
}

export function tokenLineHtml(tokens: LineTokens | null, lineNo: number): string | null {
  const line = tokens?.[lineNo - 1]
  if (!line) return null
  return line
    .map((t) => {
      let style = `color:${t.color}`
      if (t.fontStyle & 1) style += ';font-style:italic'
      if (t.fontStyle & 2) style += ';font-weight:bold'
      return `<span style="${style}">${esc(t.content)}</span>`
    })
    .join('')
}
