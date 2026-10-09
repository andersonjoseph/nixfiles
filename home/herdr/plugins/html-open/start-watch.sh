#!/usr/bin/env bash
set -u

state="$HERDR_PLUGIN_STATE_DIR"
mkdir -p "$state"
pidfile="$state/watch.pid"

# A recycled pid would also answer kill -0, so trust the pidfile only
# when the process still looks like this watcher.
pid="$(cat "$pidfile" 2>/dev/null)" || pid=""
if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && grep -aq watch.sh "/proc/$pid/cmdline" 2>/dev/null; then
  exit 0
fi

# Startup hooks are one-shot, so the watcher detaches to outlive the hook.
setsid "${HERDR_PLUGIN_ROOT:-.}/watch.sh" </dev/null >>"$state/watch.log" 2>&1 &
