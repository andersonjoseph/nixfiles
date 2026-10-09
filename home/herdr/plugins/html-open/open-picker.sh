#!/usr/bin/env bash
set -u

herdr() { "${HERDR_BIN_PATH:-herdr}" "$@"; }

die() {
  printf 'html-open: picker: %s\n' "$1" >&2
  exit 1
}

ws_id="${HERDR_WORKSPACE_ID:-}"
if [ -z "$ws_id" ]; then
  ws_id="$(printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" |
    jq -r '.workspace_id // (.workspace | if type == "object" then (.workspace_id // .id // empty) elif type == "string" then . else empty end) // empty' 2>/dev/null)"
fi
[ -n "$ws_id" ] || die 'no workspace id'

cwd="$(herdr pane list --workspace "$ws_id" 2>/dev/null |
  jq -r '(.result.panes // .panes // [])[0].cwd // empty' 2>/dev/null)"
[ -n "$cwd" ] || die "no cwd for workspace $ws_id"

herdr plugin pane open \
  --plugin anderson.html-open \
  --entrypoint picker \
  --env "HTML_OPEN_DIR=$cwd/.opencode/html-open" >/dev/null || die 'picker pane open failed'
