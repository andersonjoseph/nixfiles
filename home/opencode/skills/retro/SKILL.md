---
name: retro
description: Review the current session and its subagent sessions for friction, errors, and gotchas, then propose improvements for future runs.
argument-hint: "Optional topic or session to focus on"
disable-model-invocation: true
---

The user asked for a retrospective. Goal: find what slowed this work down and
propose concrete fixes. Facts first, no blame. Decisions stay with the user.

## 1. Gather sources

- Current session: it is already in context. Do not re-read it.
- Subagent sessions: open the session store read-only. Node 24 ships
  `node:sqlite`, no install needed:

  ```bash
  node -e '
    const {DatabaseSync} = require("node:sqlite");
    const db = new DatabaseSync(
      process.env.HOME + "/.local/share/opencode/opencode.db",
      {readOnly: true},
    );
    // children of this session by parent_id, or the recent cluster in this
    // project directory when the session id is unknown
    console.log(db.prepare(
      "SELECT id, parent_id, title, agent, cost, tokens_input, tokens_output" +
      " FROM session WHERE directory = ? ORDER BY time_updated DESC LIMIT 20",
    ).all(process.cwd()));
  '
  ```

- Read child transcripts from `message`
  (`SELECT data FROM message WHERE session_id = ?` — rows are JSON, ordered
  by `time_created`).
- Use `cost` and token totals per session as a friction signal; dig where
  they are out of line.
- Fallback for large tool results: `~/.local/share/opencode/tool-output/`.
- Never write to the database or to any file under
  `~/.local/share/opencode/`.

## 2. Mine for friction

Walk the transcripts in order. Flag:

- **Errors and retries**: failed commands, wrong flags, wrong hosts or paths,
  the same call run twice, a fix that needed more than one round.
- **Wrong turns**: exploration that found nothing, work undone by a user
  correction, compaction that dropped needed context.
- **Slow loops**: token-heavy back and forth, re-reads of the same files, a
  skill that should have been loaded and was not.
- **Permission friction**: repeated approvals, missing grants.
- **Environment gaps**: information the agent needed and could not get,
  tooling holes.

## 3. Map findings to candidate fixes

Each finding gets: one line on what happened, the friction cost, the
candidate fix, and effort (one-liner / small / project). Fix categories:

- **Guidance**: a rule or navigation pointer in the personal or team
  `AGENTS.md`, or a skill description that failed to trigger.
- **Skills**: a missing skill, or a rule inside one that no one follows.
- **Checks**: an automated check that would have caught it. Verify what
  already exists before proposing (build scripts, test suites, CI).
- **Tooling**: expensive calls, missing CLI capability.

Only findings observed in the transcripts. Mark anything inferred as
inferred.

## 4. Present and decide

- Present the findings in chat, ordered by friction cost. Write no files.
- Ask the user which findings to act on. Act only on the chosen ones.
