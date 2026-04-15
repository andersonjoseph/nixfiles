---
description: generate a structured TODO file for a topic or feature
---

Based on what we discussed, create a TODO.

Guidelines:
- Read relevant files before identifying issues. Do not read every file in the codebase to avoid bloating the context.
- For each item include: location, problem description, and suggested fix or options
- Number items sequentially
- Keep descriptions concise but actionable

Output a single TODO file with the following structure:

```

TODO: <topic>

Work through these one-by-one, checking them off as you go.

────────────────────────────────────────────────────────────────────────────────

Critical Issues

### [ ] 1. <title>

Location: <file>:<line> or <file>
Problem: <description>
Suggestion: <fix or options>

Minor Issues

### [ ] 2. <title>

...

Optional Enhancements

### [ ] 3. <title>

...

Write the TODO file to the project root as `<TOPIC>_TODO.md` (uppercase, underscores instead of spaces).
