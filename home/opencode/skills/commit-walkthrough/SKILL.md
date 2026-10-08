# Skill: commit-walkthrough

# Commit walkthrough

Walk the user through commits on one HTML page. The page is build output:
the `wt` CLI renders it from git (titles, dates, stats, message bodies,
numbered code, highlighted diff rows) plus a sidecar JSON that holds the
curated parts (why prose, pseudocode, diagrams, code coordinates, touches,
groups, line notes). Never edit the page by hand. The same sidecar plus
the same repo renders the same bytes, and a commit curated once is never
curated again.

## Flow

1. Find the commit range with this ladder, first match wins:
   - an explicit range in the ask (`A..B`, `A^..B`) → use it as given
   - "last N" or "N commits" → `HEAD~N..HEAD`
   - "this branch", "all commits in the branch" →
     `<merge-base with main>..HEAD`
   - anything else → ask the user for a range
   Before `init`, check `.opencode/walkthroughs/`: when a sidecar's
   resolved endpoints already cover the ask, render that one instead of
   starting a new walk. Pass the resolved explicit range to the CLI,
   never the natural language words, so the sidecar filename stays stable.
   The range lists commits with `--no-merges`: merge commits get no
   section.
2. Run `wt init <range> [subtitle]`. The `wt` binary comes from nix and
   sits on PATH. It migrates a v1 sidecar in place when one exists,
   creates or extends `.opencode/walkthroughs/<range>.json`, renders the
   page to `.opencode/html-open/commit-walk.html`, and prints the
   uncurated commit ids.
3. Make sure `.git/info/exclude` lists the sidecar dir
   `.opencode/walkthroughs/` and `.opencode/html-open/`; add the missing
   lines.
4. End the reply with a fenced code block tagged `open` that holds the
   absolute path of `.opencode/html-open/commit-walk.html`. The chat
   turns it into a clickable badge that opens the page in a terminal
   browser split. Stay silent in chat until the walk is done.
5. For each uncurated commit, oldest first:
   a. Read the commit: `git show <sha>` for message, diffstat, and diff.
   b. Fill that commit's entry in the sidecar, following the schema and
      the curation rules below.
   c. Run `wt render <range>` so a browser refresh shows the new section.
6. When the last commit is curated, write `overallSummary`: two or three
   short lines that state what the walk as a whole changes. Render once
   more, then post one final line in chat: the `open` fence with the page
   path and the number of commits.

## Sidecar schema, version 2

```json
{
  "schemaVersion": 2,
  "repo": "jungle-rabbit",
  "subtitle": "phase 3",
  "range": "eecc153..1454d16",
  "fingerprint": "filled by wt, do not edit",
  "overallSummary": ["one line for the whole walk", "optional second line"],
  "commits": [
    {
      "sha": "eecc153",
      "touches": "skills embed, spawn argv",
      "why": [["paragraph one, line", "wrapped"], ["optional second paragraph"]],
      "groups": [
        {
          "key": "spawn",
          "label": "spawn path",
          "category": "core",
          "summary": "one line, what this scope holds",
          "critical": false
        }
      ],
      "items": [
        {
          "title": "idea in few words",
          "group": "spawn",
          "ps": ["pseudocode lines", "  indented two spaces"],
          "diagram": ["raw html lines, see forms below"],
          "code": {
            "path": "internal/spawn.go",
            "from": 147,
            "to": 156,
            "note": ["what to notice: one", "or two lines"],
            "notes": [
              {
                "line": 150,
                "side": "additions",
                "text": "what to notice: the off-by-one guard",
                "critical": true
              }
            ]
          }
        }
      ]
    }
  ]
}
```

Every field except `sha` is optional. An item may carry only `code`, only
`ps`, or `ps` with `diagram`. A commit with items but no pseudocode gets
the prose treatment. `side` follows the diff: `additions` lines number by
the new file, `deletions` lines by the old one.

`category` is one of: ui, api, core, data, cli, security, tests, docs,
examples, deps, build, scripts, config, i18n, assets, other.

## Curation rules

- Write all sidecar text in ASD-STE100. Short sentences. No em dashes.
  Commit titles and message bodies come from git and stay as written.
- `why`: one or two short paragraphs. Why the commit exists, and what it
  changes in the architecture.
- `touches`: two to four words naming the areas the commit changes.
- `groups`: two to four per commit when the commit has more than one
  concern. The key is one short kebab word. The label reads like a scope,
  not a file list. Give each item a `group` when groups exist; items with
  no group land in an "ungrouped" bucket on the scope view. The same key
  in two commits merges into one scope card.
- `critical`: set only for security, data loss, hard to revert, or easy
  to get wrong. Most groups and notes carry no flag.
- `notes` pin to one diff line and start with `what to notice:`. Prefer a
  line note over the block `note` when the point is one spot in the diff.
- At most four items per commit. The page carries the few things that
  matter, not every hunk.
- Items read top to bottom, like one call walking the stack. Start where
  the request enters: the endpoint, handler, or tool, with its inputs, its
  validations, and every refusal answer it gives (status codes, tool
  errors). Then follow the call down: service rules, types and interfaces,
  returns, storage, side effects. One layer, one item, with code,
  pseudocode, or a diagram as it fits. When a commit changes layers that no
  single call walks, order them by the life of the system: boot first,
  then the serving path, then one-off commands. The `why` prose reads the
  same way: start where the request enters.
- `ps` shows the shape of the logic, not the syntax. Plain words,
  two-space indent, no types, at most 8 lines.
- Verify every code range before you write it into the sidecar:
  `git show <sha>:<path> | nl -ba | sed -n '<from>,<to>p'`
  The CLI pulls the code from that commit, never from the working
  tree, so a wrong range shows wrong code.
- Commits that only change tests, docs, or plans get prose only, with no
  pseudocode blocks.

## Diagram rules

One diagram per item at most. Pick the form by this table:

| Situation | Form |
| --- | --- |
| Status or state transitions change | states |
| A race or message order between actors caused a bug | seq |
| Call structure, argv, or an envelope shape changes | tree |
| Pseudocode alone is clear | no diagram |

Write `item.diagram` as one of these JSON shapes. The CLI renders the
HTML and SVG, and it validates the data: a broken diagram fails the
render with the commit and item named, so fix the sidecar and render
again.

states, one row per transition, `dir` picks the color:
```json
{ "kind": "states", "rows": [
  { "from": "running", "to": "report rejected", "dir": "del" },
  { "from": "running", "to": "reported", "dir": "add", "note": "late report lands" }
] }
```

seq, two to six actors, every message labeled, at most fourteen:
```json
{ "kind": "seq", "actors": ["Spawn", "Child", "Broker"], "msgs": [
  { "from": "Spawn", "to": "Child", "text": "seed dir" },
  { "from": "Child", "to": "Broker", "text": "late report", "tone": "bad" },
  { "from": "Broker", "to": "Spawn", "text": "accepted", "tone": "good" }
] }
```

tree, `mark` adds the plus or minus, `file` renders dim, three levels at
most:
```json
{ "kind": "tree", "root": "Spawn", "children": [
  { "label": "seed agent dir" },
  { "label": "writeChildSkill", "mark": "add", "file": "internal/skills.go" },
  { "label": "TabCreate as the only path", "mark": "del" }
] }
```

For a shape these three cannot express, `diagram` may carry raw HTML
lines as in version 1. Use it rarely; the CLI renders the lines as
written.

## Determinism rules

- Never edit `commit-walk.html` by hand. Fix the sidecar, then render
  again.
- Never reword an already curated commit. If the user asks for changes,
  edit that sidecar entry, then render.
- Reruns must stay silent: if every commit in the sidecar is curated,
  `init` and `render` alone answer the request, with no model curation.
- Code rows are real diffs. For each block the CLI renders the commit's
  hunks that overlap the curated range (new-file line numbers): green
  rows for added lines, red rows for removed lines, plain context rows,
  old and new line numbers in two gutters, and a dot row between hunks.
  Line notes render as amber rows inside the diff, red when critical.
  When no hunk overlaps the range, the block falls back to the file
  snapshot at the commit.
- Shiki highlights every code row at build time, with a version pinned by
  nix. No network, no install step, no runtime highlighter. The same
  sidecar plus the same repo renders the same bytes.
- The page has one file, works offline, and carries all styles and
  scripts inline.
