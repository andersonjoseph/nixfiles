# hunk-notes — persist hunk review comments per commit, re-apply after switches.
set -euo pipefail

usage() {
  cat <<'EOF'
hunk-notes — keep hunk review comments in .hunk/notes.json across sessions

  hunk-notes save [ref]     store the live session's comments under ref
                            (inferred from the session title when omitted)
  hunk-notes apply <ref>    load ref into the live session and apply its notes
  hunk-notes next           apply the next stored ref
  hunk-notes prev           apply the previous stored ref
  hunk-notes list           show stored refs and note counts
  hunk-notes rm <ref>       drop a stored ref

ref is a commit sha (opens with `show`) or a range A..B (opens with `diff`).
EOF
  exit 0
}

die() { echo "hunk-notes: $*" >&2; exit 1; }

REPO=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repository"
STORE="$REPO/.hunk/notes.json"
mkdir -p "$REPO/.hunk"
[ -s "$STORE" ] || printf '{"order":[],"notes":{}}\n' > "$STORE"

session_ref() {
  hunk session get --repo "$REPO" 2>/dev/null \
    | sed -n 's/^Title: [^ ]* \(show \)\{0,1\}//p' | head -1
}

cmd=${1:-}; [ -n "$cmd" ] || usage
shift || true

case "$cmd" in
  save)
    ref=${1:-$(session_ref)}
    ref=${ref#show }
    [ -n "$ref" ] || die "no live session and no ref given"
    notes=$(mktemp)
    hunk session comment list --repo "$REPO" --type all --json \
      | jq '[.comments[] | {filePath, newLine: (.newLine // .oldLine), summary}]' > "$notes"
    count=$(jq 'length' "$notes")
    [ "$count" -gt 0 ] || die "the live session has no comments to save"
    jq --arg r "$ref" --slurpfile n "$notes" \
      '.notes[$r] = $n[0] | if (.order | index($r)) then . else .order += [$r] end' \
      "$STORE" > "$STORE.tmp"
    mv "$STORE.tmp" "$STORE"
    echo "saved $count notes under $ref"
    ;;
  apply)
    ref=${1:-}
    [ -n "$ref" ] || die "apply needs a ref (sha or A..B)"
    count=$(jq -r --arg r "$ref" '(.notes[$r] // []) | length' "$STORE")
    [ "$count" -gt 0 ] || die "no notes stored for $ref (see: hunk-notes list)"
    case $ref in
      *..*) hunk session reload --repo "$REPO" -- diff "$ref" >/dev/null ;;
      *)    hunk session reload --repo "$REPO" -- show "$ref" >/dev/null ;;
    esac
    hunk session comment clear --repo "$REPO" --yes >/dev/null 2>&1 || true
    jq --arg r "$ref" '{comments: .notes[$r]}' "$STORE" \
      | hunk session comment apply --repo "$REPO" --stdin >/dev/null
    echo "applied $count notes for $ref"
    ;;
  next|prev)
    cur=$(session_ref)
    [ -n "$cur" ] || die "no live hunk session"
    idx=$(jq --arg r "$cur" '.order | index($r) // -1' "$STORE")
    n=$(jq '.order | length' "$STORE")
    case $cmd in next) i=$((idx + 1)) ;; prev) i=$((idx - 1)) ;; esac
    [ "$i" -ge 0 ] && [ "$i" -lt "$n" ] || die "no $cmd ref; you are at a boundary (current: $cur)"
    ref=$(jq -r ".order[$i]" "$STORE")
    exec "$0" apply "$ref"
    ;;
  list)
    jq -r '. as $r | .order[] | "\(.) — \($r.notes[.] | length) notes"' "$STORE"
    ;;
  rm)
    ref=${1:?rm needs a ref}
    jq --arg r "$ref" '.order -= [$r] | .notes = (.notes | del(.[$r]))' "$STORE" > "$STORE.tmp"
    mv "$STORE.tmp" "$STORE"
    echo "dropped $ref"
    ;;
  *)
    usage
    ;;
esac
