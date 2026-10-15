---
name: retro
description: Review the current session and its subagent sessions for friction, errors, and gotchas, then propose improvements for future runs.
argument-hint: "Optional topic or session to focus on"
disable-model-invocation: true
---

Goal: find what slowed this work down and propose concrete fixes. Facts first,
no blame. Decisions stay with the user.

## 1. Gather sources

- Current session: already in context — do not re-read it.
- Subagent sessions: the session store, read-only. Node 24 ships `node:sqlite`:

  ```bash
  node -e '
    const {DatabaseSync} = require("node:sqlite");
    const db = new DatabaseSync(
      process.env.HOME + "/.local/share/opencode/opencode.db",
      {readOnly: true},
    );
    console.log(db.prepare(
      "SELECT id, parent_id, title, agent, cost, tokens_input, tokens_output" +
      " FROM session WHERE directory = ? ORDER BY time_updated DESC LIMIT 20",
    ).all(process.cwd()));
  '
  ```

- Child transcripts: `SELECT data FROM message WHERE session_id = ?` — rows are
  JSON, ordered by `time_created`.
- Use `cost` and token totals per session as a friction signal; dig where they
  are out of line.
- Large tool results: `~/.local/share/opencode/tool-output/`.
- Never write to the database or anything under `~/.local/share/opencode/`.

## 2. Mine for friction

Walk the transcripts in order; flag errors and retries (failed commands, wrong
flags or paths, the same call twice), wrong turns (dead-end exploration, work
undone by a correction), slow loops (token-heavy back-and-forth, re-read files,
a skill that should have loaded and did not), permission friction, and
environment gaps.

## 3. Map findings to fixes

Each finding: one line on what happened, the friction cost, the candidate fix,
and effort (one-liner / small / project). Fixes land in guidance (AGENTS.md
rules, skill descriptions), skills, checks (verify what already exists before
proposing), or tooling. Only findings observed in the transcripts; mark
inferences as inferred.

## 4. Present and decide

Present findings in chat, ordered by friction cost. Write no files. Ask which
to act on; act only on the chosen ones.
