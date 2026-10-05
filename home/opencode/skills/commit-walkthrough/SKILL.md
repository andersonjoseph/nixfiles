---
name: commit-walkthrough
description: Explain a series of commits on one self-contained HTML page, built deterministically by a script from git plus a curated sidecar JSON. One section per commit, plain language, pseudocode for each important change, expandable to the real code with file and line numbers. Use when the user asks to walk through, explain, or review a range of commits.
---

# Commit walkthrough

Walk the user through commits on one HTML page. The page is build output:
a script renders it from git (titles, dates, stats, message bodies,
numbered code) plus a sidecar JSON that holds the curated parts (why
prose, pseudocode, diagrams, code coordinates, touches). Never edit the
page by hand. The same sidecar plus the same repo renders the same bytes,
and a commit curated once is never curated again.

## Flow

1. Find the commit range with this ladder, first match wins:
   - an explicit range in the ask (`A..B`, `A^..B`) → use it as given
   - "last N" or "N commits" → `HEAD~N..HEAD`
   - "this branch", "all commits in the branch" →
     `<merge-base with main>..HEAD`
   - anything else → ask the user for a range
   Before `init`, check `.opencode/walkthroughs/`: when a sidecar's
   resolved endpoints already cover the ask, render that one instead of
   starting a new walk. Pass the resolved explicit range to the script,
   never the natural language words, so the sidecar filename stays stable.
   The script lists commits with `git rev-list --no-merges`: merge commits
   get no section.
2. Run (`<skill-dir>` is the directory this SKILL.md lives in, as the
   skill tool reports it; build.sh cds to the repo root itself, so it
   works from any subdirectory):
   `bash <skill-dir>/build.sh init <range> [subtitle]`
   It creates `.opencode/walkthroughs/<range>.json` when missing, adds
   commits that are not in it yet, renders `commit-walk.html`, and prints
   the uncurated commit ids.
3. Make sure `.git/info/exclude` lists `commit-walk.html` and the sidecar
   dir `.opencode/walkthroughs/`; add the missing lines.
4. Post the page path in chat and tell the user to open it in a browser.
   Then stay silent in chat until the walk is done.
5. For each uncurated commit, oldest first:
   a. Read the commit: `git show <sha>` for message, diffstat, and diff.
   b. Fill that commit's entry in the sidecar, following the schema and
      the curation rules below.
   c. Run `bash <skill-dir>/build.sh render <range>` so a
      browser refresh shows the new section.
6. Post one final line in chat: the page path and the number of commits.

## Sidecar schema

```json
{
  "repo": "jungle-rabbit",
  "subtitle": "phase 3",
  "range": "eecc153..1454d16",
  "commits": [
    {
      "sha": "eecc153",
      "touches": "skills embed, spawn argv",
      "why": [["paragraph one, line", "wrapped"], ["optional second paragraph"]],
      "items": [
        {
          "title": "idea in few words",
          "ps": ["pseudocode lines", "  indented two spaces"],
          "diagram": ["raw html lines, see forms below"],
          "code": {"path": "internal/spawn.go", "from": 147, "to": 156,
                   "note": ["what to notice: one", "or two lines"]}
        }
      ]
    }
  ]
}
```

Every field except `sha` is optional. An item may carry only `code`, only
`ps`, or `ps` with `diagram`. A commit with items but no pseudocode gets
the prose treatment.

## Curation rules

- Write all sidecar text in ASD-STE100. Short sentences. No em dashes.
  Commit titles and message bodies come from git and stay as written.
- `why`: one or two short paragraphs. Why the commit exists, and what it
  changes in the architecture.
- `touches`: two to four words naming the areas the commit changes.
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
  The script pulls the code from that commit, never from the working
  tree, so a wrong range shows wrong code.
- `note` lines start with `what to notice:` and name the one thing worth
  seeing in the block.
- Commits that only change tests, docs, or plans get prose only, with no
  pseudocode blocks.

## Diagram rules

One diagram per item at most. Pick the form by this table:

| Situation | Form |
| --- | --- |
| Status or state transitions change | states chips |
| A race or message order between actors caused a bug | svg sequence |
| Call structure, argv, or an envelope shape changes | tree with add/del marks |
| Pseudocode alone is clear | no diagram |

Forms, copy exactly:

states chips:
```html
<div class="states">
  <div class="del"><span class="st">running</span><span class="ar">&#8594;</span><span class="st st-x">report rejected</span></div>
  <div class="add"><span class="st">running</span><span class="ar">&#8594;</span><span class="st st-ok">reported</span> <span class="dim">late report lands</span></div>
</div>
```

tree with add/del marks:
```html
<ul class="tree">
  <li>Spawn
    <ul>
      <li>seed agent dir with links</li>
      <li class="add"><span class="sig">+</span>writeChildSkill <span class="dim">internal/skills.go</span></li>
      <li class="del"><span class="sig">-</span>TabCreate as the only path</li>
    </ul>
  </li>
</ul>
```

svg sequence: lanes as dashed `<line class="lane">`, actors as
`<rect class="actor">` with `<text>`, messages as `<line class="msg">`
with `marker-end` arrows, classes `bad` and `good` for red and green.
Keep it under 220 units tall and label every arrow.

Indent diagram lines with six spaces at the top level so they land
correctly inside the view div.

## Determinism rules

- Never edit `commit-walk.html` by hand. Fix the sidecar or the script,
  then render again.
- Never reword an already curated commit. If the user asks for changes,
  edit that sidecar entry, then render.
- Reruns must stay silent: if every commit in the sidecar is curated,
  `init` and `render` alone answer the request, with no model curation.
- Code rows are escaped plain text. No highlighter runs and the script
  has no Python dependency. The same sidecar plus the same repo renders
  the same bytes.
- Code blocks are real diffs. For each block the script renders the
  commit's hunks that overlap the curated range (new-file line numbers):
  green rows for added lines, red rows for removed lines, plain context
  rows, old and new line numbers in two gutters, and a dot row between
  hunks. When no hunk overlaps the range, the
  block falls back to the file snapshot at the commit.
