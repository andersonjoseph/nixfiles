---
name: hunk-review
description: "Interacts with live Hunk diff review sessions via CLI. Inspects review focus, navigates files and hunks, reloads session contents, and adds inline review comments. Use when the user has a Hunk session running or wants to review diffs interactively. IMPORTANT: When the user asks you to check reviews on Hunk, do NOT jump to implementation. Start a discussion first — clarify what they want reviewed, what concerns they have, and agree on scope before taking any action."
---

# Hunk Review

Hunk is an interactive terminal diff viewer. The TUI is for the user — do NOT run `hunk diff`, `hunk show`, or other interactive commands. Use `hunk session *` CLI commands only.

If no session exists, ask the user to launch Hunk in their terminal first.

---

## Copy-Paste Templates

Use these exactly as shown. Replace only the placeholders in CAPS.

### Find sessions

```bash
hunk session list --json
```

### Get review structure (files + hunk indices, NO diff text)

```bash
hunk session review --repo . --json
```

### Get diff text for specific files

IMPORTANT: `--include-patch` can produce huge output. Always save to file first, then `jq` from file. NEVER pipe `--include-patch` directly into `jq`.

```bash
hunk session review --repo . --include-patch --json > /tmp/hunk-review.json
jq '.review.files[] | select(.path == "FILENAME")' /tmp/hunk-review.json
```

### Check what the user is looking at

```bash
hunk session context --repo . --json
```

### Navigate to a file + line

```bash
hunk session navigate --repo . --file PATH/IN/DIFF --new-line 42
hunk session navigate --repo . --file PATH/IN/DIFF --hunk 1
```

Relative (jumps between commented hunks, no `--file` needed):

```bash
hunk session navigate --repo . --next-comment
hunk session navigate --repo . --prev-comment
```

### Add a single comment

```bash
hunk session comment add --repo . --file PATH/IN/DIFF --new-line 42 --summary "Your summary" --focus
```

### Add multiple comments at once (BATCH)

Use this exact pattern. Heredoc avoids all shell escaping issues:

```bash
cat <<'JSONEOF' | hunk session comment apply --repo . --stdin --focus
{"comments":[
  {"filePath":"src/foo.go","newLine":42,"summary":"Short review note","rationale":"Optional longer explanation"},
  {"filePath":"src/bar.go","newLine":100,"summary":"Another note"}
]}
JSONEOF
```

**JSON field rules (do NOT deviate):**
- `filePath` — string, path as shown in diff
- `summary` — string, required
- `rationale` — string, optional
- Exactly ONE target per comment: `newLine` (int), `oldLine` (int), or `hunkNumber` (int). All are 1-based integers, NOT strings.
- Do NOT use `printf` — the heredoc above handles everything.
- Do NOT include trailing commas in the JSON array.

### List existing comments

```bash
hunk session comment list --repo . --json
hunk session comment list --repo . --type user --json
hunk session comment list --repo . --file PATH/IN/DIFF --json
```

### Delete comments

`comment rm` is broken with `--repo` flag. Use the session ID as a positional argument, OR use `clear`:

```bash
# Delete one comment (must use session ID, NOT --repo)
hunk session comment rm SESSION_ID COMMENT_ID

# Delete all comments on a specific file (uses --repo, works fine)
hunk session comment clear --repo . --yes --file PATH/IN/DIFF

# Delete ALL comments in session
hunk session comment clear --repo . --yes
```

### Reload the diff

```bash
hunk session reload --repo . -- diff
hunk session reload --repo . -- diff main...feature -- src/ui/
hunk session reload --repo . -- show HEAD~1
hunk session reload --repo . -- diff --exclude-untracked
```

Always include `--` before the nested command.

---

## JSON output shapes

### `review --json` structure

```json
{
  "review": {
    "sessionId": "...",
    "title": "...",
    "repoRoot": "...",
    "selectedFile": { "id": "...", "path": "...", "additions": N, "deletions": N, "hunkCount": N, "hunks": [...] },
    "selectedHunk": { "index": N, "oldRange": [start, end], "newRange": [start, end] },
    "files": [
      {
        "id": "...",
        "path": "src/foo.go",
        "additions": N,
        "deletions": N,
        "hunkCount": N,
        "hunks": [
          { "index": 0, "header": "@@ ...", "oldRange": [start, end], "newRange": [start, end] }
        ]
      }
    ]
  }
}
```

With `--include-patch`, each file also gets a `"patch"` string field containing the raw unified diff. Without it, there is NO patch field.

### `context --json` structure

```json
{
  "context": {
    "sessionId": "...",
    "selectedFile": { "id": "...", "path": "...", "additions": N, "deletions": N, "hunkCount": N },
    "selectedHunk": { "index": N, "oldRange": [start, end], "newRange": [start, end] },
    "liveCommentCount": N
  }
}
```

### `comment list --json` structure

```json
{
  "comments": [
    {
      "commentId": "mcp:uuid:N",
      "filePath": "src/foo.go",
      "hunkIndex": 0,
      "side": "new",
      "line": 42,
      "summary": "...",
      "rationale": "...",
      "createdAt": "..."
    }
  ]
}
```

### Working `jq` recipes

```bash
# List all file paths
hunk session review --repo . --json | jq '.review.files[] | .path'

# Hunks for one file
hunk session review --repo . --json | jq '.review.files[] | select(.path | contains("foo.go")) | .hunks[] | {index, oldRange, newRange}'

# Diff text for one file (MUST save to file first with --include-patch)
hunk session review --repo . --include-patch --json > /tmp/hunk-review.json
jq '.review.files[] | select(.path == "src/foo.go") | .patch' -r /tmp/hunk-review.json
```

---

## Session selection

All commands use `--repo .` (matches session whose repo root is `.`). Alternatives:
- `--repo <path>` — match by repo root
- `<session-id>` — positional, match by exact ID (use when multiple sessions share a repo)
- If only one session exists, it auto-resolves

For `reload` only: `--session-path <path>` matches by window cwd, `--source <path>` runs the diff command from a different checkout.

---

## Guiding a review

1. `hunk session review --repo . --json` — get structure without diff text
2. Save `--include-patch` to `/tmp/hunk-review.json` and `jq` from file for diff text
3. Navigate before commenting so the user sees the code
4. Use the batch `comment apply` heredoc template for multiple notes
5. Use `--focus` to jump the viewport to the note

Guidelines:
- Work in the order that tells the clearest story, not file order
- Use `comment apply` (batch) for agent reviews; `comment add` for one-off notes
- Keep comments focused: intent, structure, risks, or follow-ups
- Don't comment on every hunk — highlight what the user wouldn't spot themselves

---

## Common errors

| Error | Fix |
|---|---|
| "No visible diff file matches ..." | File not in loaded review. Check `context`, then `reload`. |
| "No active Hunk sessions" | Ask user to open Hunk, or retry with sandbox escalation. |
| "Multiple active sessions match" | Pass `<session-id>` explicitly. |
| "Pass the replacement Hunk command after `--`" | Include `--` before the nested `diff`/`show` in `reload`. |
| "Pass --stdin to read batch comments from stdin JSON." | `comment apply` requires `--stdin` flag. |
| "Specify exactly one navigation target" | Pick one: `--hunk`, `--old-line`, or `--new-line`. |
| `comment rm` says "missing required argument 'commentId'" | `--repo` flag is broken for `rm`. Use session ID positional: `hunk session comment rm SESSION_ID COMMENT_ID`. Or use `comment clear --file`. |
| `jq` parse error on review output | `--include-patch` output is too large to pipe. Save to file first: `> /tmp/hunk-review.json` then `jq ... /tmp/hunk-review.json`. |
