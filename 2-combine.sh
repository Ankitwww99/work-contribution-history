#!/usr/bin/env bash
# =============================================================================
# 2-combine.sh  —  RUN ONCE, after you've extracted all repos.
# =============================================================================
# Merges every records/*.tsv into a single all-records.tsv,
# de-duplicated globally and sorted oldest -> newest.
#
# HOW TO USE:   bash 2-combine.sh
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

shopt -s nullglob
FILES=(records/*.tsv)
[ ${#FILES[@]} -gt 0 ] || { echo "ERROR: no records/*.tsv found. Run 1-extract-repo.sh first." >&2; exit 1; }

OUT="all-records.tsv"

# Messages that are ALLOWED to repeat back-to-back (generic, not accidental dups).
# Matched case-insensitively against the WHOLE message. Edit freely.
GENERIC_RE='^(review +)?fix(es)?$'

# Concatenate, sort oldest->newest by date (field 2), then drop a commit only when
# it is CONSECUTIVE with an identical (org, repo, message) — i.e. an accidental
# back-to-back duplicate. Non-adjacent repeats of the same message are kept.
# Generic messages (GENERIC_RE) are never collapsed.
TAB="$(printf '\t')"
cat "${FILES[@]}" \
  | sort -t"$TAB" -k2,2 \
  | awk -F"$TAB" -v generic="$GENERIC_RE" '
      {
        key = $3 FS $4 FS $5          # org + repo + message
        is_generic = (tolower($5) ~ generic)
        if (!is_generic && key == prev) next   # skip consecutive duplicate
        print
        prev = key
      }' \
  > "$OUT"

echo ">> Combined ${#FILES[@]} file(s) -> $OUT"
echo ">> Total unique commits: $(grep -c . "$OUT")"
echo ">> Date range: $(head -n1 "$OUT" | cut -f2)  ..  $(tail -n1 "$OUT" | cut -f2)"
