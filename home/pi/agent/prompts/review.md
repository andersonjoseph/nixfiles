---
description: Run a code review in a sub-agent, then discuss findings
---

Run a code review in a sub-agent and bring the findings back for discussion.

## Target

$@

If no target is specified, review uncommitted changes.

## Reading the review

Findings are tagged with priority levels:
- **[P0]** — Drop everything. Blocking release/operations. Universal issues only.
- **[P1]** — Urgent. Should be addressed next cycle.
- **[P2]** — Normal. Fix eventually.
- **[P3]** — Low. Nice to have.

The review ends with **Human Reviewer Callouts (Non-Blocking)** — informational items for awareness (migrations, dependency changes, auth, etc.). These don't affect the verdict.

## Steps

1. Determine the review target and construct the sub-agent prompt:
   - If no target was given, use: `/review-guidelines`
   - If a target was given, use: `/review-guidelines <target>`
2. Spawn a separate pi instance in print mode:
   ```bash
   pi -p "<constructed prompt>" --no-session > /tmp/review-output.md
   ```
3. Read the output from `/tmp/review-output.md`.
4. Present the findings to the user, then ask which findings they want to address, which to skip, and whether anything needs clarification.
5. Do NOT edit any files or make any changes until the user explicitly asks you to.
