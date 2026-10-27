---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to the project's agent-local directory — `.omp/handoff-<topic>.md` under omp, `.pi/handoff-<topic>.md` under pi, `.claude/handoff-<topic>.md` under claude — it stays local (add the pattern to `.git/info/exclude` when the repo tracks that directory), never elsewhere in the workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should load (`/skill:<name>` under omp and pi, by name under claude).

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
