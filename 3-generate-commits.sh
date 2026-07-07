#!/usr/bin/env bash
# =============================================================================
# 3-generate-commits.sh  —  writes back-dated commits into a SEPARATE clean repo.
# =============================================================================
# Replays every record in all-records.tsv as an empty, back-dated commit whose
# message is:  {Organization}: {repo}: {commit message}
# The commit's author date == the original commit date, so your green squares
# land on the days you actually worked.
#
# This toolkit repo stays clean — the commits are created in TARGET_REPO, a
# different repo you push to your profile. Reuse this toolkit for future orgs.
#
# HOW TO USE:
#   1. Create + clone your clean graph repo somewhere, e.g.
#        git clone git@github.com:you/contribution-history.git ~/contribution-history
#   2. Point TARGET_REPO at it (below), or pass it as an argument.
#   3. Make sure THAT repo's user.email is LINKED + VERIFIED on GitHub.
#   4. bash 3-generate-commits.sh              (or: bash 3-generate-commits.sh /path/to/repo)
#   5. cd into TARGET_REPO and: git push
# =============================================================================

set -euo pipefail

# ------------------------------- CONFIG --------------------------------------
# The clean repo that will hold ONLY the contribution commits.
# Leave as-is and pass the path as an argument, or hard-code it here.
TARGET_REPO="${1:-/Users/ankitbansal/Desktop/P/contribution-history}"
# -----------------------------------------------------------------------------

TOOLKIT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$TOOLKIT_DIR/all-records.tsv"
[ -f "$SRC" ] || { echo "ERROR: $SRC not found. Run 2-combine.sh first." >&2; exit 1; }

# Validate the target repo.
[ -d "$TARGET_REPO/.git" ] || {
  echo "ERROR: '$TARGET_REPO' is not a git repo." >&2
  echo "       Create it first:  git clone <your-clean-repo-url> \"$TARGET_REPO\"" >&2
  exit 1
}
[ "$(cd "$TARGET_REPO" && pwd)" != "$TOOLKIT_DIR" ] || {
  echo "ERROR: TARGET_REPO must NOT be this toolkit repo — keep them separate." >&2
  exit 1
}

cd "$TARGET_REPO"
EMAIL="$(git config user.email || true)"
NAME="$(git config user.name || true)"
total="$(grep -c . "$SRC")"
echo ">> Target repo : $TARGET_REPO"
echo ">> Authored as : $NAME <$EMAIL>"
echo ">>   ^ this email MUST be added & verified on your GitHub account, or squares stay grey."
echo ">> Will create $total back-dated commits here."
read -r -p ">> Continue? [y/N] " ok
[ "$ok" = "y" ] || [ "$ok" = "Y" ] || { echo "Aborted."; exit 0; }

i=0
# TSV columns: hash <TAB> date <TAB> org <TAB> repo <TAB> subject
while IFS=$'\t' read -r hash date org repo subject; do
  [ -z "${date:-}" ] && continue
  i=$((i + 1))
  MSG="${org}: ${repo}: ${subject}"
  GIT_AUTHOR_DATE="$date" GIT_COMMITTER_DATE="$date" \
    git commit --allow-empty --quiet -m "$MSG"
  if [ $((i % 200)) -eq 0 ]; then echo "   ...$i/$total"; fi
done < "$SRC"

echo ">> Done: created $i back-dated commits in $TARGET_REPO"
echo ">> Now run:  cd \"$TARGET_REPO\" && git push"
