import { describe, expect, it } from 'vitest'
import { DiagramError, renderDiagram, type SeqDiagram } from '../src/diagram'

describe('states', () => {
  it('renders add and del rows with the right chip classes', () => {
    const html = renderDiagram({
      kind: 'states',
      rows: [
        { from: 'running', to: 'report rejected', dir: 'del' },
        { from: 'running', to: 'reported', dir: 'add', note: 'late report lands' },
      ],
    })
    expect(html).toContain('<div class="del">')
    expect(html).toContain('<span class="st st-x">report rejected</span>')
    expect(html).toContain('<div class="add">')
    expect(html).toContain('<span class="st st-ok">reported</span>')
    expect(html).toContain('<span class="dim">late report lands</span>')
  })

  it('escapes names and rejects a bad dir', () => {
    const html = renderDiagram({ kind: 'states', rows: [{ from: 'a<b>', to: 'c&d', dir: 'add' }] })
    expect(html).toContain('a&lt;b&gt;')
    expect(() => renderDiagram({ kind: 'states', rows: [{ from: 'a', to: 'b', dir: 'nope' as 'add' }] })).toThrow(DiagramError)
  })
})

describe('tree', () => {
  it('renders marks, sigs, file dims, and nesting', () => {
    const html = renderDiagram({
      kind: 'tree',
      root: 'Spawn',
      children: [
        { label: 'seed agent dir' },
        { label: 'writeChildSkill', mark: 'add', file: 'internal/skills.go', children: [{ label: 'link dirs' }] },
        { label: 'TabCreate', mark: 'del' },
      ],
    })
    expect(html).toContain('<span class="sig">+</span>writeChildSkill <span class="dim">internal/skills.go</span>')
    expect(html).toContain('<span class="sig">-</span>TabCreate')
    expect(html).toContain('<li class="add">')
    expect(html.match(/<ul>/g)?.length).toBe(2)
  })

  it('rejects nesting past three levels', () => {
    const deep = {
      kind: 'tree',
      root: 'a',
      children: [{ label: 'b', children: [{ label: 'c', children: [{ label: 'd', children: [{ label: 'e' }] }] }] }],
    }
    expect(() => renderDiagram(deep as never)).toThrow(/three levels/)
  })
})

describe('seq', () => {
  const seq: SeqDiagram = {
    kind: 'seq',
    actors: ['Spawn', 'Child', 'Broker'],
    msgs: [
      { from: 'Spawn', to: 'Child', text: 'seed dir' },
      { from: 'Child', to: 'Broker', text: 'late report', tone: 'bad' as const },
      { from: 'Broker', to: 'Spawn', text: 'accepted', tone: 'good' as const },
    ],
  }

  it('draws one lane and box per actor, arrows between lanes', () => {
    const html = renderDiagram(seq, 't1')
    expect(html.match(/class="lane"/g)?.length).toBe(3)
    expect(html.match(/class="actor"/g)?.length).toBe(3)
    expect(html).toContain('url(#ah-bad-t1)')
    expect(html).toContain('url(#ah-good-t1)')
    expect(html).toContain('>late report</text>')
    expect(html).toContain('viewBox="0 0 408 150"')
  })

  it('grows height with messages and escapes labels', () => {
    const html = renderDiagram({ kind: 'seq', actors: ['a<x>', 'b'], msgs: [{ from: 'a<x>', to: 'b', text: 'hi' }] }, 't2')
    expect(html).toContain('a&lt;x&gt;')
    expect(html).toContain('viewBox="0 0 258 98"')
  })

  it('rejects unknown actors, duplicates, and self messages', () => {
    expect(() => renderDiagram({ kind: 'seq', actors: ['a', 'b'], msgs: [{ from: 'a', to: 'zz', text: 'x' }] }, 'e1')).toThrow(/not an actor/)
    expect(() => renderDiagram({ kind: 'seq', actors: ['a', 'a'], msgs: [{ from: 'a', to: 'a', text: 'x' }] }, 'e2')).toThrow(/unique/)
    expect(() => renderDiagram({ kind: 'seq', actors: ['a', 'b'], msgs: [{ from: 'a', to: 'a', text: 'x' }] }, 'e3')).toThrow(/self/)
  })
})

describe('legacy passthrough', () => {
  it('joins raw html lines unchanged', () => {
    expect(renderDiagram(['<div class="states">', '</div>'])).toBe('<div class="states">\n</div>')
  })

  it('rejects garbage', () => {
    expect(() => renderDiagram(42 as never)).toThrow(DiagramError)
    expect(() => renderDiagram({ kind: 'nope' } as never)).toThrow(/kind must be/)
  })
})
