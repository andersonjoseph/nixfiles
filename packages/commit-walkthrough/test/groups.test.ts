import { describe, expect, it } from 'vitest'
import { categoryForPath, draftGroups } from '../src/groups'

describe('categoryForPath', () => {
  it('classifies by path rules before extension rules', () => {
    expect(categoryForPath('src/api/routes.ts')).toBe('api')
    expect(categoryForPath('src/components/Button.tsx')).toBe('ui')
    expect(categoryForPath('src/auth/token.ts')).toBe('security')
    expect(categoryForPath('migrations/0001_init.sql')).toBe('data')
    expect(categoryForPath('flake.nix')).toBe('build')
    expect(categoryForPath('scripts/release.sh')).toBe('scripts')
    expect(categoryForPath('README.md')).toBe('docs')
    expect(categoryForPath('src/parser.test.ts')).toBe('tests')
    expect(categoryForPath('cmd/wt/main.go')).toBe('cli')
    expect(categoryForPath('.github/workflows/ci.yml')).toBe('config')
  })

  it('falls back to core for code and other for the rest', () => {
    expect(categoryForPath('internal/spawn.go')).toBe('core')
    expect(categoryForPath('logo.png')).toBe('assets')
    expect(categoryForPath('Makefile')).toBe('other')
  })
})

describe('draftGroups', () => {
  it('drafts one group per category in a fixed order', () => {
    const draft = draftGroups(['src/components/x.ts', 'flake.nix', 'src/core.go', 'src/components/y.ts'])
    expect(draft.map((g) => g.key)).toEqual(['ui', 'core', 'build'])
    expect(draft[0]).toMatchObject({ key: 'ui', label: 'ui', category: 'ui' })
  })

  it('is deterministic for the same files in any order', () => {
    const a = draftGroups(['b.md', 'a.ts'])
    const b = draftGroups(['a.ts', 'b.md'])
    expect(a).toEqual(b)
  })

  it('returns nothing for an empty change set', () => {
    expect(draftGroups([])).toEqual([])
  })
})
