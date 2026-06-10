---
name: commit
description: Reviews staged git changes (diff --cached) and commits them. Use when the user asks to commit, especially after staging files themselves. Always inspect the diff before committing.
---

# Commit Workflow

Two-step review-then-commit workflow.

## Steps

1. **Review staged changes:**
   ```bash
   git diff --cached --stat
   git diff --cached
   ```
   Read the full diff. Summarize what changed across all files.

2. **Commit:**
   Write a concise commit message summarizing the changes. Use imperative mood. Do NOT commit until you have shown the user what will be committed.
