---
name: show-me
description: Help the user understand the current topic visually with concise diagrams, code-shape sketches, and rich visuals on the sideshow board.
disable-model-invocation: true
---

Help the user understand the current topic visually. Skip the preamble, keep prose brief, pick the smallest view that makes the point. One example per shape — match the shape to the topic, not the other way around.

Logic or algorithm — pseudocode:

```text
on(save)
  if content is unchanged
    return cached result
  write new content
  return fresh result
```

Runtime control flow — call tree:

```text
submitForm
  createSession
    persistPrompt
    launchAgent
  navigateToSession
```

UI structure — component tree with the state and module boundaries that matter:

```tsx
<SessionPage> (apps/example/src/routes/session.tsx)
  useSessionEvents()
  <SessionToolbar>
    <RunSkillButton> (packages/ui)
```

File responsibility or a broad refactor — shallow file tree:

```text
src/
|-- commands/       # parses user actions
|-- sessions/       # owns session state
`-- transport/      # sends API requests
```

Interaction or data flow across actors — ASCII sequence:

```text
User        UI         Daemon
  |          |           |
  |--choose->|           |
  |          |--prompt-->|
  |          |<--stream--|
```

What changes inside an existing shape — diff:

```diff
  submitForm
    createSession
      persistPrompt
+     expandSkillMention
      launchAgent
```

Show the whole block only when it is mostly new or the user needs a copyable target — otherwise excerpt.

For anything too dense for ASCII — UI, layout, state comparison, concept — draw it on the sideshow board (the `sideshow` skill): html surfaces for mockups and dense explainers, mermaid for structure. Never write an HTML file; standalone HTML only when the user explicitly asks for a file.
