---
description: generate a structured TODO file for a topic or feature
---

Create a todo $@

Guidelines:
- Read relevant files before identifying issues. Do not read every file in the codebase to avoid bloating the context.
- Categorize issues by severity: Critical, Minor, Optional
- For each item include: location, problem description, and suggested fix or options
- Number items sequentially
- Keep descriptions concise but actionable
- Focus on real issues, not style nitpicks

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
