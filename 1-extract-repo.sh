#!/usr/bin/env bash
# =============================================================================
# 1-extract-repo.sh  —  RUN ONCE PER WORK REPO, WHILE YOU STILL HAVE ACCESS.
# =============================================================================
# Finds every commit YOU authored, across ALL branches, and writes one record
# per commit into the central tracking repo (with de-duplication by commit hash).
#
# Matches your commits by EMAIL *or* by NAME/USERNAME — because some of your
# commits are attributed by email and some only by your git username.
#
# HOW TO USE:
#   1. Edit the CONFIG block below once (your emails + usernames + tracking dir).
#   2. cd into a freshly-cloned work repo.
#   3. Run:  bash /path/to/1-extract-repo.sh
#   Repeat step 2-3 for every repo.
# =============================================================================

set -euo pipefail

# ------------------------------- CONFIG --------------------------------------
# All the identities you have EVER committed under. Add as many as you need.
EMAILS=(
  "ankit.bansal@devslane.com"
  "ankit@northstar.dental"
)
USERNAMES=(
  "Ankit-Devslane"
)
# Where the central records live (your personal tracking repo).
TRACKING_DIR="/Users/ankitbansal/Desktop/P/work-contribution-history"
# -----------------------------------------------------------------------------

# Must be run from inside a git repo.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: run this from INSIDE a cloned work repo." >&2; exit 1; }

# Make sure every branch is present locally (remote-only branches are otherwise missed).
echo ">> Fetching all branches so nothing is missed..."
git fetch --all --prune --quiet || echo "   (fetch failed — continuing with whatever is local)"

# Derive ORG and REPO from the origin remote (git@github.com:ORG/REPO.git or https://.../ORG/REPO.git)
REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
# Pure-bash parsing (macOS/BSD sed has no non-greedy operator).
_url="${REMOTE%.git}"     # drop trailing .git
_url="${_url%/}"          # drop trailing slash
REPO="${_url##*/}"        # last path segment
_rest="${_url%/*}"        # everything before the last /
ORG="${_rest##*[:/]}"     # segment after the last : or /
[ -z "$ORG"  ] && ORG="UNKNOWN_ORG"
[ -z "$REPO" ] && REPO="$(basename "$(pwd)")"
echo ">> Repo identified as: ${ORG}/${REPO}"

# Build one big case-insensitive regex from all emails + usernames.
FILTER="$(printf '%s\n' "${EMAILS[@]}" "${USERNAMES[@]}" | paste -sd '|' -)"

mkdir -p "$TRACKING_DIR/records"
OUT="$TRACKING_DIR/records/${ORG}-${REPO}.tsv"

# Columns:  hash <TAB> ISO-author-date <TAB> ORG <TAB> REPO <TAB> subject
# --all         : every branch/ref (merge commits included)
# sort -u -k1,1 : de-duplicate a commit that appears on multiple branches
# -E : extended regex, so the "|" between identities means OR (git defaults to
#      basic regex, where "|" is a literal pipe and matches nothing).
git log --all -E --regexp-ignore-case --author="$FILTER" \
    --pretty=format:"%H%x09%aI%x09${ORG}%x09${REPO}%x09%s" \
  | sort -u -t"$(printf '\t')" -k1,1 \
  > "$OUT"

COUNT="$(grep -c . "$OUT" || echo 0)"
echo ">> Wrote $COUNT unique commits -> $OUT"
