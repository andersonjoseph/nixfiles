#!/usr/bin/env bash
set -u

dir="${HTML_OPEN_DIR:?}"

shopt -s nullglob
pages=("$dir"/*.html)
shopt -u nullglob

if [ "${#pages[@]}" -eq 0 ]; then
  printf 'no html pages in %s\n' "$dir"
  sleep 2
  exit 0
fi

choice="$(printf '%s\n' "${pages[@]##*/}" | fzf --height 100% --prompt 'open html page > ')"
[ -n "$choice" ] || exit 0
printf '%s\n' "$choice" >>"$dir/.requests"
