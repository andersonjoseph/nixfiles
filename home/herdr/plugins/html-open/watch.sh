#!/usr/bin/env bash
set -u
export LC_ALL=C

state="$HERDR_PLUGIN_STATE_DIR"
mkdir -p "$state"
pidfile="$state/watch.pid"

# Headless hosts never install terminal-browser; linked or not, idle here.
command -v terminal-browser >/dev/null 2>&1 || exit 0

# A recycled pid would also answer kill -0, so trust the pidfile only
# when the process still looks like this watcher.
watcher_alive() {
  pid="$(cat "$pidfile" 2>/dev/null)" || return 1
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null && grep -aq watch.sh "/proc/$pid/cmdline" 2>/dev/null
}

watcher_alive && exit 0
echo $$ >"$pidfile"

herdr() { "${HERDR_BIN_PATH:-herdr}" "$@"; }

log() {
  printf 'html-open: [%s] %s\n' "$(date +%FT%T)" "$1" >&2
}

workspace_ids() {
  herdr workspace list 2>/dev/null |
    jq -r '(.result.workspaces // .workspaces // [])[] | (.workspace_id // .id)' 2>/dev/null
}

# Workspace records carry no cwd, pane records do. One pane list call
# yields both the workspace cwd and the pane to split.
pane_facts() {
  herdr pane list --workspace "$1" 2>/dev/null |
    jq -r 'def panes: .result.panes // .panes // [];
      def pane_of(f): panes | map(select(f)) | first | .pane_id // empty;
      [(panes | first | .cwd // empty),
       (pane_of(.focused) // (panes | first | .pane_id // empty))] | @tsv' 2>/dev/null
}

open_page() {
  path="$1"
  target="${2:-}"
  pane_env=()
  [ -n "$target" ] && pane_env=(HERDR_PANE_ID="$target")
  # terminal-browser owns the herdr split itself; the pane id env aims
  # the split at the producing workspace, and the cli exits once the
  # pane is wired up.
  out="$(env TERMINAL_BROWSER_NO_TELEMETRY=1 "${pane_env[@]}" \
    terminal-browser open "file://$path" --split right 2>&1)" || {
    log "terminal-browser open failed for $path: ${out:0:200}"
    return 1
  }
}

declare -A seen
declare -A dir_known
declare -A requests_offset
declare -A failures

# Exit 0: opened. Exit 1: failed, retry on a later pass. Exit 2: failed
# three times, give up so a broken entrypoint cannot loop forever.
try_open() {
  path="$1"
  target="$2"
  if open_page "$path" "$target"; then
    unset "failures[$path]" 2>/dev/null || true
    return 0
  fi
  failures[$path]=$(( ${failures[$path]:-0} + 1 ))
  [ "${failures[$path]}" -gt 3 ] && return 2
  return 1
}

while :; do
  while read -r ws_id; do
    [ -n "${ws_id:-}" ] || continue
    ws_cwd=""
    ws_pane=""
    IFS=$'\t' read -r ws_cwd ws_pane < <(pane_facts "$ws_id")
    [ -n "${ws_cwd:-}" ] || continue
    dir="$ws_cwd/.opencode/html-open"
    [ -d "$dir" ] || continue

    for key in "${!seen[@]}"; do
      case "$key" in
        "$dir"/*) [ -f "$key" ] || unset "seen[$key]" ;;
      esac
    done

    first_sight=0
    if [ -z "${dir_known[$dir]:-}" ]; then
      dir_known[$dir]=1
      first_sight=1
    fi

    for path in "$dir"/*.html; do
      [ -f "$path" ] || continue
      [ -z "${seen[$path]:-}" ] || continue
      if [ "$first_sight" = 1 ]; then
        seen[$path]=1
        continue
      fi
      try_open "$path" "$ws_pane"
      rc=$?
      [ "$rc" != 1 ] && seen[$path]=1
    done

    requests="$dir/.requests"
    if [ -f "$requests" ]; then
      size="$(stat -c %s "$requests" 2>/dev/null)" || continue
      offset="${requests_offset[$dir]:-}"
      if [ -z "$offset" ]; then
        requests_offset[$dir]=$size
      elif [ "$size" -gt "$offset" ]; then
        new_offset=$offset
        while IFS= read -r line; do
          case "$line" in
            *.html)
              target_file="$dir/$line"
              if [ -f "$target_file" ]; then
                try_open "$target_file" "$ws_pane"
                rc=$?
                [ "$rc" = 2 ] && log "giving up on request $line"
                [ "$rc" = 1 ] && break
              fi
              ;;
          esac
          new_offset=$((new_offset + ${#line} + 1))
        done < <(tail -c +"$((offset + 1))" "$requests")
        requests_offset[$dir]=$new_offset
      else
        requests_offset[$dir]=$size
      fi
    fi
  done < <(workspace_ids)
  sleep 2
done
