#!/usr/bin/env bash
# Builds the commit-walk page. Mechanical content (titles, dates, stats,
# message bodies, numbered code) comes from git. Curated content (why prose,
# pseudocode, diagrams, code coordinates, touches) comes from a sidecar JSON,
# one per range. The same sidecar plus the same repo renders the same bytes.
#
# usage:
#   build.sh init   <range> [subtitle]   create or extend the sidecar, render
#   build.sh render <range>              render commit-walk.html
set -euo pipefail

[ $# -ge 2 ] || { echo "usage: $0 init <range> [subtitle] | render <range>" >&2; exit 2; }
cmd=$1
range=$2
subtitle=${3:-}

root=$(git rev-parse --show-toplevel)
cd "$root"
page=$root/commit-walk.html
walkdir=$root/.opencode/walkthroughs
sidecar=$walkdir/$(printf '%s' "$range" | tr -c 'A-Za-z0-9' '_').json

esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"$1"; }

new_commit_json() {
  printf '{"sha": "%s", "touches": null, "why": [], "items": []}' "$(git rev-parse --short=7 "$1")"
}

do_init() {
  mkdir -p "$walkdir"
  if [ ! -f "$sidecar" ]; then
    {
      printf '{\n'
      printf '  "repo": "%s",\n' "$(basename "$root")"
      printf '  "subtitle": "%s",\n' "$subtitle"
      printf '  "range": "%s",\n' "$range"
      printf '  "commits": [\n'
      first=1
      while read -r sha; do
        [ $first = 1 ] || printf ',\n'
        first=0
        printf '    %s' "$(new_commit_json "$sha")"
      done < <(git rev-list --no-merges --reverse "$range")
      printf '\n  ]\n}\n'
    } > "$sidecar"
  else
    tmp=$(mktemp)
    cp "$sidecar" "$tmp"
    while read -r sha; do
      short=$(git rev-parse --short=7 "$sha")
      next=$(mktemp)
      jq --arg s "$short" '
        .repo = (.repo // $repo)
        | .range = $range
        | if $sub != "" then .subtitle = $sub else . end
        | .commits += (if ([.commits[].sha] | index($s)) then [] else [{
            sha: $s, touches: null, why: [], items: []
          }] end)
      ' --arg repo "$(basename "$root")" --arg range "$range" --arg sub "$subtitle" "$tmp" > "$next"
      mv "$next" "$tmp"
    done < <(git rev-list --no-merges --reverse "$range")
    mv "$tmp" "$sidecar"
  fi
  do_render
  uncurated=$(jq -r '[.commits[] | select((.why | length) == 0) | .sha] | join(" ")' "$sidecar")
  echo "sidecar: $sidecar"
  if [ -n "$uncurated" ]; then
    echo "uncurated: $uncurated"
  fi
}

numbered_code() { # sha path from to -> html rows with line numbers
  local src
  src=$(git show "$1:$2" | sed -n "$3,$4p")
  printf '%s\n' "$src" | awk -v start="$3" '{
    line = $0
    gsub(/&/, "\\&amp;", line)
    gsub(/</, "\\&lt;", line)
    gsub(/>/, "\\&gt;", line)
    printf "<div class=\"cl\"><span class=\"ln\">%d</span>%s</div>\n", start + NR - 1, line
  }'
}

# diff_rows renders the commit's real diff hunks that overlap the curated
# range (new-file line numbers): red rows for removed lines, green rows for
# added lines, context rows plain, old and new line numbers in two gutters,
# a dot row between hunks. Rows are escaped plain text.
diff_rows() { # sha path from to -> rows, empty when no hunk overlaps
  local sha=$1 path=$2 from=$3 to=$4 d
  d=$(git diff --no-color --unified=3 "$sha^" "$sha" -- "$path" 2>/dev/null) || true
  [ -n "$d" ] || return 0
  printf '%s\n' "$d" | awk -v from="$from" -v to="$to" '
    function esc_(s) { gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s); return s }
    # flush prints a buffered hunk when its new-file span meets [from,to]
    function flush(   i, overlap, content, row) {
      if (bi == 0) return
      overlap = 0
      if (hcount > 0) { if (hfrom <= to && hfrom + hcount - 1 >= from) overlap = 1 }
      else if (hfrom >= from && hfrom <= to + 1) overlap = 1   # pure deletion sits between hfrom-1 and hfrom
      if (!overlap) { bi = 0; return }
      if (printed) print "<div class=\"cl gap\">&#183;&#183;&#183;</div>"
      printed = 1
      for (i = 1; i <= bi; i++) {
        content = esc_(bx[i])
        if (bt[i] == "add")
          row = "<div class=\"cl add\"><span class=\"g old\"></span><span class=\"g new\">" bn[i] "</span><span class=\"sg\">+</span>"
        else if (bt[i] == "del")
          row = "<div class=\"cl del\"><span class=\"g old\">" bo[i] "</span><span class=\"g new\"></span><span class=\"sg\">-</span>"
        else
          row = "<div class=\"cl\"><span class=\"g old\">" bo[i] "</span><span class=\"g new\">" bn[i] "</span><span class=\"sg\"></span>"
        print row content "</div>"
      }
      bi = 0
    }
    /^@@/ {
      flush()
      ostart = nstart = 0; ocount = ncount = 1
      if (match($0, /-[0-9]+(,[0-9]+)?/)) {
        split(substr($0, RSTART + 1, RLENGTH - 1), a, ",")
        ostart = a[1] + 0; ocount = (a[2] == "" ? 1 : a[2] + 0)
      }
      if (match($0, /\+[0-9]+(,[0-9]+)?/)) {
        split(substr($0, RSTART + 1, RLENGTH - 1), a, ",")
        nstart = a[1] + 0; ncount = (a[2] == "" ? 1 : a[2] + 0)
      }
      oln = ostart; nln = nstart
      hfrom = nstart; hcount = ncount
      bi = 0; inhunk = 1
      next
    }
    inhunk && /^\\/ { next }   # "\ No newline at end of file"
    inhunk && /^\+/ { bi++; bt[bi] = "add"; bn[bi] = nln; bo[bi] = ""; bx[bi] = substr($0, 2); nln++; next }
    inhunk && /^-/  { bi++; bt[bi] = "del"; bo[bi] = oln; bn[bi] = ""; bx[bi] = substr($0, 2); oln++; next }
    inhunk          { bi++; bt[bi] = "ctx"; bo[bi] = oln; bn[bi] = nln; bx[bi] = substr($0, 2); oln++; nln++ }
    END { flush() }
  '
}

item_html() { # item-json sec idx
  local item=$1 sec=$2 idx=$3
  local title ps diagram hasps hasdia
  title=$(jq -r '.title // ""' <<<"$item")
  hasps=$(jq '(.ps // []) | length > 0' <<<"$item")
  hasdia=$(jq '(.diagram // []) | length > 0' <<<"$item")

  if [ -n "$title" ]; then
    printf '  <h3>%s</h3>\n' "$(esc "$title")"
  fi
  if $hasdia && $hasps; then
    local n="s${sec}i${idx}"
    printf '  <div class="views">\n'
    printf '    <input class="d" type="radio" name="%s" id="%sd" checked>\n' "$n" "$n"
    printf '    <input class="p" type="radio" name="%s" id="%sp">\n' "$n" "$n"
    printf '    <label class="d" for="%sd">diagram</label>\n' "$n"
    printf '    <label class="p" for="%sp">pseudocode</label>\n' "$n"
    printf '    <div class="view d">\n%s\n    </div>\n' "$(jq -r '(.diagram // []) | join("\n")' <<<"$item")"
    printf '    <div class="view p"><pre class="ps">%s</pre></div>\n' "$(esc "$(jq -r '(.ps // []) | join("\n")' <<<"$item")")"
    printf '  </div>\n'
  elif $hasps; then
    printf '  <pre class="ps">%s</pre>\n' "$(esc "$(jq -r '(.ps // []) | join("\n")' <<<"$item")")"
  elif $hasdia; then
    printf '  <div class="diagram">\n%s\n  </div>\n' "$(jq -r '(.diagram // []) | join("\n")' <<<"$item")"
  fi

  if jq -e '.code != null' <<<"$item" >/dev/null; then
    local path from to note rows verb
    path=$(jq -r '.code.path' <<<"$item")
    from=$(jq -r '.code.from' <<<"$item")
    to=$(jq -r '.code.to' <<<"$item")
    rows=$(diff_rows "$sha" "$path" "$from" "$to")
    verb="real code"
    if [ -n "$rows" ]; then
      verb="diff"
    else
      rows=$(numbered_code "$sha" "$path" "$from" "$to")
    fi
    printf '  <details>\n'
    printf '    <summary>show %s: %s:%s-%s</summary>\n' "$verb" "$(esc "$path")" "$from" "$to"
    printf '    <pre class="code">%s</pre>\n' "$rows"
    if jq -e '(.code.note // []) | length > 0' <<<"$item" >/dev/null; then
      printf '    <p class="ctx">%s</p>\n' "$(esc "$(jq -r '.code.note | join("\n")' <<<"$item" | sed '2,$s/^/    /')")"
    fi
    printf '  </details>\n'
  fi
}

do_render() {
  [ -f "$sidecar" ] || { echo "no sidecar for range $range at $sidecar" >&2; exit 1; }
  local repo sub total curated out i=0
  repo=$(jq -r '.repo // ""' "$sidecar"); [ -n "$repo" ] || repo=$(basename "$root")
  sub=$(jq -r '.subtitle // ""' "$sidecar")
  total=$(jq '.commits | length' "$sidecar")
  curated=$(jq '[.commits[] | select((.why | length) > 0)] | length' "$sidecar")
  out=$(mktemp)

  cat > "$out" <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>commit walk</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; background: #0d1117; color: #c9d1d9; font: 16px/1.6 system-ui, sans-serif; }
  header { border-bottom: 1px solid #30363d; padding: 2rem 0 1rem; }
  header h1 { margin: 0 0 .25rem; font-size: 1.4rem; }
  header p { margin: .2rem 0; color: #8b949e; }
  section.commit { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem 1.25rem 1.25rem; margin: 1.5rem 0; }
  h2 { font-size: 1.1rem; margin: .2rem 0 .4rem; }
  h2 code { color: #8b949e; font-size: .85rem; font-weight: normal; }
  p.meta { color: #8b949e; font-size: .85rem; margin: .2rem 0 .8rem; }
  blockquote.msg { margin: .5rem 0; padding: .5rem .9rem; border-left: 3px solid #388bfd; background: #0d1117; color: #8b949e; white-space: pre-wrap; }
  h3 { font-size: .95rem; margin: 1rem 0 .3rem; color: #e6edf3; }
  pre { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: .8rem 1rem; overflow-x: auto; font: 13px/1.5 ui-monospace, monospace; }
  pre.ps { border-color: #2ea04366; }
  details { margin: .4rem 0 1rem; }
  summary { cursor: pointer; color: #58a6ff; font-family: ui-monospace, monospace; font-size: .85rem; }
  summary:hover { color: #79c0ff; }
  p.ctx { color: #8b949e; font-size: .9rem; margin: .4rem 0 0; }
  p.todo { color: #8b949e; font-style: italic; }
  .views { margin: .3rem 0 .6rem; }
  .views > input { position: absolute; opacity: 0; pointer-events: none; }
  .views > label { display: inline-block; cursor: pointer; font: .78rem ui-monospace, monospace; color: #8b949e; border: 1px solid #30363d; border-bottom: none; border-radius: 6px 6px 0 0; padding: .2rem .7rem; margin: 0 .2rem 0 0; position: relative; top: 1px; }
  .views > label:hover { color: #c9d1d9; }
  .views > input:checked ~ label { color: #58a6ff; background: #0d1117; border-color: #388bfd; }
  .views > .view { display: none; border: 1px solid #30363d; border-radius: 0 6px 6px 6px; background: #0d1117; padding: .8rem 1rem; overflow-x: auto; }
  .views > input.d:checked ~ div.view.d { display: block; }
  .views > input.p:checked ~ div.view.p { display: block; }
  .views pre.ps { border: none; padding: 0; background: none; }
  ul.tree { list-style: none; margin: 0; padding: 0; font: 13px/1.8 ui-monospace, monospace; }
  ul.tree ul { padding-left: 1.2rem; margin: 0; }
  ul.tree li { position: relative; padding-left: 1rem; }
  ul.tree li::before { content: ""; position: absolute; left: 0; top: 0; bottom: -.1rem; border-left: 1px solid #30363d; }
  ul.tree li::after { content: ""; position: absolute; left: 0; top: .9em; width: .7rem; border-top: 1px solid #30363d; }
  ul.tree li:last-child::before { bottom: auto; height: .9em; }
  ul.tree li.add { color: #3fb950; }
  ul.tree li.del { color: #f85149; }
  .sig { display: inline-block; width: .8rem; font-weight: bold; }
  .dim { color: #8b949e; }
  .states > div { margin: .35rem 0; font-size: .9rem; }
  .states > div.add::before { content: "+ "; color: #3fb950; font-family: ui-monospace, monospace; }
  .states > div.del::before { content: "- "; color: #f85149; font-family: ui-monospace, monospace; }
  .st { display: inline-block; border: 1px solid #30363d; border-radius: 999px; padding: 0 .55rem; font: .8rem/1.5 ui-monospace, monospace; color: #c9d1d9; }
  .st-ok { border-color: #3fb950; color: #3fb950; }
  .st-x { border-color: #f85149; color: #f85149; }
  .ar { color: #8b949e; margin: 0 .35rem; }
  svg.seq { width: 100%; height: auto; display: block; }
  svg.seq text { font: 11px ui-monospace, monospace; fill: #c9d1d9; }
  svg.seq .lane { stroke: #30363d; stroke-dasharray: 4 4; }
  svg.seq .actor { fill: #161b22; stroke: #388bfd; }
  svg.seq .msg { stroke: #388bfd; stroke-width: 1.5; }
  svg.seq .bad { stroke: #f85149; }
  svg.seq .good { stroke: #3fb950; }
  main { display: block; max-width: 60rem; margin: 0 auto; padding: 0 1rem 6rem; }
HEAD
  cat >> "$out" <<'HEAD2'
  pre.code .ln { display: inline-block; width: 3.4rem; color: #6e7681; text-align: right; padding-right: .9rem; user-select: none; }
  pre.code { white-space: normal; }
  pre.code div.cl { white-space: pre; }
  pre.code .g { display: inline-block; width: 2.4rem; color: #6e7681; text-align: right; padding-right: .5rem; user-select: none; }
  pre.code .sg { display: inline-block; width: .9rem; user-select: none; }
  pre.code div.cl.add { background: rgba(46, 160, 67, .15); border-radius: 2px; }
  pre.code div.cl.del { background: rgba(248, 81, 73, .15); border-radius: 2px; }
  pre.code div.cl.add .sg { color: #3fb950; }
  pre.code div.cl.del .sg { color: #f85149; }
  pre.code div.cl.add .g.new { color: #3fb950; }
  pre.code div.cl.del .g.old { color: #f85149; }
  pre.code div.cl.gap { color: #6e7681; text-align: center; user-select: none; }
</style>
</head>
<body>
<main>
HEAD2

  {
    printf '<header>\n'
    printf '  <h1>commit walk: %s</h1>\n' "$(esc "$repo")"
    if [ -n "$sub" ]; then
      printf '  <p>%s, %s, %s commits, oldest first</p>\n' "$(esc "$sub")" "$(esc "$range")" "$total"
    else
      printf '  <p>%s, %s commits, oldest first</p>\n' "$(esc "$range")" "$total"
    fi
    printf '  <p>progress: <strong class="progress">%s of %s</strong></p>\n' "$curated" "$total"
    printf '</header>\n'
  } >> "$out"

  while read -r c; do
    i=$((i + 1))
    sha=$(jq -r '.sha' <<<"$c")
    title=$(git log -1 --format=%s "$sha")
    date=$(git log -1 --format=%as "$sha")
    read -r files add rem < <(git show --numstat --format= "$sha" | awk 'NF{f++; a+=($1=="-"?0:$1); r+=($2=="-"?0:$2)} END{print f+0, a+0, r+0}')
    touches=$(jq -r '.touches // ""' <<<"$c")

    {
      printf '<section class="commit" id="sec%s">\n' "$i"
      printf '  <h2>%s. %s <code>%s</code></h2>\n' "$i" "$(esc "$title")" "$sha"
      if [ -n "$touches" ]; then
        printf '  <p class="meta">%s, %s files, +%s -%s · touches: %s</p>\n' "$date" "$files" "$add" "$rem" "$(esc "$touches")"
      else
        printf '  <p class="meta">%s, %s files, +%s -%s</p>\n' "$date" "$files" "$add" "$rem"
      fi
      body=$(git log -1 --format=%b "$sha")
      if [ -n "$body" ]; then
        printf '  <blockquote class="msg">%s</blockquote>\n' "$(esc "$body")"
      fi
      if [ "$(jq '.why | length' <<<"$c")" -eq 0 ]; then
        printf '  <p class="todo">not curated yet</p>\n'
      else
        jq -r '.why | map("<p>" + (join("\n") | @html) + "</p>") | join("\n")' <<<"$c" | sed 's/^/  /' >> "$out"
      fi
      j=0
      while read -r item; do
        j=$((j + 1))
        item_html "$item" "$i" "$j"
      done < <(jq -c '.items[]' <<<"$c")
      printf '</section>\n'
    } >> "$out"
  done < <(jq -c '.commits[]' "$sidecar")

  printf '<!-- sections go here -->\n</main>\n</body>\n</html>\n' >> "$out"
  mv "$out" "$page"
  echo "wrote $page ($curated of $total curated)"
}

case $cmd in
  init) do_init ;;
  render) do_render ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
