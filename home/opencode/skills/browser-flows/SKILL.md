---
name: browser-flows
description: Verify browser work with recorded flows and debug live pages on the shared Chrome. Use when a task needs the browser, a flow in the index matches it, or a browser bug must be reproduced or fixed.
---

Lab root: `~/projects/browser-flows`. Read `~/projects/browser-flows/flows/INDEX.md`
before any browser interaction. Never explore a page blind when a flow exists.

1. Verify with one call from the lab root: `bin/flows flows/<file>.mjs`.
   Exit 0 is green. The stdout JSON carries per-step status, console errors,
   failed requests, and the report path. Failure screenshots land next to
   `report.json`. Flows attach to the shared Chrome on :9222 when it runs,
   else launch headless — either way they are safe to run without asking.
2. Start the shared Chrome when the user should watch or a flow needs logins:
   `bin/chrome-debug start` (headed, persistent profile). `stop` and `status`
   manage it. Tell the user the window is shared — they can drive it any time.
3. Debug red flows and unknown pages with the `chrome-devtools` MCP tools
   (take_snapshot, list_console_messages, list_network_requests). They attach
   to the same :9222 Chrome. Prefer snapshot over screenshot; read console
   stacks before guessing.
4. No flow for the task? Ask the user to teach it, then stop and wait:
   - user records in DevTools (F12) → Recorder panel → exports JSON, then
     `nix develop ~/projects/browser-flows -c node scripts/convert-replay.mjs <export.json> flows/<name>.mjs`
   - or drive the shared Chrome via MCP while the user dictates, then write
     the flow by hand with `step()` from `lib/harness.mjs`.
   Run the new flow once so the user sees it green before moving on.
5. Bug reports: turn the recorded repro into a flow plus the expected
   assertion, run it red, fix the code, rerun to green. The flow stays as the
   regression check.
6. After adding or editing any flow, regenerate the index:
   `nix develop ~/projects/browser-flows -c node scripts/index.mjs`

## Remote agent, local browser

The lab also runs when the agent is on a headless machine and the shared Chrome
lives on the user's desktop. An SSH reverse tunnel (`RemoteForward 9222
127.0.0.1:9222` in the desktop's ssh config) makes `127.0.0.1:9222` on this
machine mean that Chrome, so flows and MCP tools attach with no config change.

- Chrome must be started on the desktop first: `bin/chrome-debug start`.
- If a flow reports `mode: "launched-headless"` and it needs logins or the
  user's session, stop and ask the user to start the shared Chrome — do not
  retry blind. The fallback profile is fresh and on this machine's IP.
- Recorder exports from the desktop arrive by scp or rsync; convert them here
  with the same command.
- While attached, sites see the desktop's IP and cookies. Treat the session as
  privileged; never tunnel over an untrusted network.

Keep flows read-only or reversible on external sites: no purchases, deletes,
or message sends unless the user asked for them in that flow.
