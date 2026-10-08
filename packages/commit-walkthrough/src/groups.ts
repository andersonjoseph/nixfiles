import type { Category, Group } from './render'

const RULES: [RegExp, Category][] = [
  [/\.test\.[jt]sx?$|\.spec\.[jt]sx?$|(^|\/)tests?\/|_test\.(go|py)$/, 'tests'],
  [/\.mdx?$/i, 'docs'],
  [/(^|\/)(examples?|playground|demos?)\//, 'examples'],
  [/package(-lock)?\.json$|pnpm-lock\.yaml$|\.lock$|(^|\/)node_modules\//, 'deps'],
  [/\.nix$|flake\.lock$/, 'build'],
  [/(^|\/)(scripts?|tools|bin|gens)\/|\.sh$/, 'scripts'],
  [/(^|\/)(components?|views?|pages?|layouts?|widgets)\//, 'ui'],
  [/\.(css|scss|vue|svelte|astro)$/, 'ui'],
  [/(^|\/)(api|routes?|handlers?|controllers?|endpoints?|graphql)\//, 'api'],
  [/(^|\/)(auth|security|permissions?|secrets?)\//, 'security'],
  [/(^|\/)(migrations?|schemas?|models?|entities|db|storage|stores?)\//, 'data'],
  [/\.sql$/, 'data'],
  [/^cmd\//, 'cli'],
  [/(^|\/)(locales?|i18n|translations?)\//, 'i18n'],
  [/\.json$|\.ya?ml$|\.toml$|\.ini$|\.env/, 'config'],
  [/^\.github\//, 'config'],
  [/\.(png|jpe?g|gif|svg|ico|woff2?|ttf)$/, 'assets'],
]

const CODE_EXT = /\.(ts|tsx|js|jsx|mjs|cjs|go|py|rs|rb|java|kt|c|h|cpp|zig|lua|nix|sh)$/

const CATEGORY_ORDER: Category[] = [
  'ui',
  'api',
  'core',
  'data',
  'cli',
  'security',
  'tests',
  'docs',
  'examples',
  'deps',
  'build',
  'scripts',
  'config',
  'i18n',
  'assets',
  'other',
]

export function categoryForPath(path: string): Category {
  for (const [re, category] of RULES) {
    if (re.test(path)) return category
  }
  if (CODE_EXT.test(path)) return 'core'
  return 'other'
}

export function draftGroups(files: string[]): Group[] {
  const byCategory = new Map<Category, string[]>()
  for (const f of files) {
    const c = categoryForPath(f)
    const list = byCategory.get(c) ?? []
    list.push(f)
    byCategory.set(c, list)
  }
  return [...byCategory.entries()]
    .sort((a, b) => CATEGORY_ORDER.indexOf(a[0]) - CATEGORY_ORDER.indexOf(b[0]))
    .map(([category]) => ({ key: category, label: category, category }))
}
