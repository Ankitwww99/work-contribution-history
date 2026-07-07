#!/usr/bin/env bash
# =============================================================================
# 2.5-preview.sh  —  DRY RUN. Shows exactly what 3-generate-commits.sh WILL do,
#                    without creating a single commit.
# =============================================================================
# Reads all-records.tsv and prints:
#   - totals, date range, how many distinct green-square days
#   - a per-repo breakdown
#   - a per-month histogram (rough shape of your contribution graph)
#   - a sample of the real commit messages, in final {org}-{repo}-{msg} format
#
# HOW TO USE:   bash 2.5-preview.sh          (run after 2-combine.sh)
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

SRC="all-records.tsv"
[ -f "$SRC" ] || { echo "ERROR: $SRC not found. Run 2-combine.sh first." >&2; exit 1; }

TOTAL="$(grep -c . "$SRC")"
DAYS="$(cut -f2 "$SRC" | cut -dT -f1 | sort -u | wc -l | tr -d ' ')"
FIRST="$(cut -f2 "$SRC" | sort | head -n1 | cut -dT -f1)"
LAST="$(cut -f2 "$SRC" | sort | tail -n1 | cut -dT -f1)"

echo "============================================================"
echo " PREVIEW — nothing is committed"
echo "============================================================"
echo " Total commits to be created : $TOTAL"
echo " Distinct days (green squares): $DAYS"
echo " Date range                  : $FIRST  ..  $LAST"
echo

echo "------ commits per repo ------------------------------------"
# field3 = org, field4 = repo
awk -F'\t' '{print $3"/"$4}' "$SRC" | sort | uniq -c | sort -rn
echo

echo "------ commits per month (shape of your graph) -------------"
# YYYY-MM  count  bar
cut -f2 "$SRC" | cut -c1-7 | sort | uniq -c \
  | awk '{ n=$1; bar=""; for(i=0;i<n && i<60;i++) bar=bar"#"; printf "  %s  %4d  %s\n", $2, n, bar }'
echo

echo "------ sample commit messages (final format) ---------------"
echo "  first 8:"
head -n8 "$SRC" | awk -F'\t' '{printf "    %s  %s: %s: %s\n", substr($2,1,10), $3, $4, $5}'
echo "  ..."
echo "  last 4:"
tail -n4 "$SRC" | awk -F'\t' '{printf "    %s  %s: %s: %s\n", substr($2,1,10), $3, $4, $5}'
echo
echo "============================================================"

# ---- Also write the FULL, ordered preview to a file you can open/scroll ------
OUTFILE="preview.txt"
{
  echo "PREVIEW — exactly what 3-generate-commits.sh will create (nothing committed yet)"
  echo "Total commits : $TOTAL   |   Distinct days : $DAYS   |   Range : $FIRST .. $LAST"
  echo
  echo "commits per repo:"
  awk -F'\t' '{print $3"/"$4}' "$SRC" | sort | uniq -c | sort -rn | sed 's/^/  /'
  echo
  echo "commits per month:"
  cut -f2 "$SRC" | cut -c1-7 | sort | uniq -c \
    | awk '{ n=$1; bar=""; for(i=0;i<n && i<60;i++) bar=bar"#"; printf "  %s  %4d  %s\n", $2, n, bar }'
  echo
  echo "FULL commit list (date  ->  message as it will appear):"
  echo "-------------------------------------------------------"
  awk -F'\t' '{printf "%s  %s: %s: %s\n", substr($2,1,10), $3, $4, $5}' "$SRC"
} > "$OUTFILE"

echo " Full preview written to: $OUTFILE  ($TOTAL lines)"
echo "   open it with:  less $OUTFILE"
echo "============================================================"
echo " Looks right? ->  bash 3-generate-commits.sh"
echo "============================================================"
