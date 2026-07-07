# work-contribution-history

A small toolkit to **preserve your GitHub contribution graph** when you leave an
organization (or any time you lose access to repos you committed to).

It scans each work repo for the commits **you** authored — across all branches,
matched by email *or* username — records them, and replays them as back-dated
commits in a separate personal repo, so the green squares land on the days you
actually worked.

> This repo is the **reusable toolkit**. The back-dated commits are written into
> a *separate* clean repo (e.g. `contribution-history`) so this toolkit never
> gets tangled up with the generated history. Reuse it for every future org.

---

## How it works

The contribution graph counts a commit when its **author date** falls on a day and
the **author email is linked to your GitHub account**. These scripts capture the
real author dates + messages from your old repos and re-emit them under your
personal email — so the graph reflects work you genuinely did.

```
old work repos  ──(1-extract)──►  records/*.tsv
                                       │
                                  (2-combine)
                                       │
                                       ▼
                               all-records.tsv  ──(2.5-preview)──►  preview.txt
                                       │
                                 (3-generate)
                                       ▼
                        clean repo: back-dated commits ──► git push ──► green graph
```

---

## Scripts

| Script | Run where | What it does |
|--------|-----------|--------------|
| `1-extract-repo.sh` | inside **each** old work repo | Finds every commit you authored (all branches, matched by email/username), dedupes by hash, writes `records/{org}-{repo}.tsv` |
| `2-combine.sh` | this toolkit repo | Merges all `records/*.tsv` → `all-records.tsv`, sorted by date, collapsing *consecutive* duplicate messages |
| `2.5-preview.sh` | this toolkit repo | Dry run — prints a summary and writes the full list to `preview.txt`. Creates nothing. |
| `3-generate-commits.sh` | this toolkit repo, targets a **separate** repo | Replays each record as an empty back-dated commit into your clean repo |

Commit message format: `{Organization}: {repo}: {commit message}`

---

## One-time setup

Edit the **CONFIG block** at the top of `1-extract-repo.sh`:

```bash
EMAILS=(
  "you@oldcompany.com"          # every email you ever committed under
  "you@personal.com"
)
USERNAMES=(
  "Your-GitHub-Handle"          # git author names / usernames you used
)
TRACKING_DIR="/absolute/path/to/work-contribution-history"
```

To discover exactly which identities you used in a repo:

```bash
git log --all --format="%an <%ae>" | sort | uniq -c | sort -rn
```

Add **every** variant that is you — including GitHub `noreply` emails like
`12345+You@users.noreply.github.com`.

---

## Usage

### Step 1 — extract (do this WHILE YOU STILL HAVE ACCESS ⚠️)

Access disappears when you leave. Fully clone each repo, then extract:

```bash
git clone --no-single-branch <repo-url>
cd <repo>
bash /path/to/work-contribution-history/1-extract-repo.sh
```

The script fetches all branches, derives org/repo from the remote, and writes
`records/{org}-{repo}.tsv`. Re-running on the same repo is safe (deduped).
Repeat for every repo.

### Step 2 — combine

```bash
cd /path/to/work-contribution-history
bash 2-combine.sh
```

Produces `all-records.tsv` and prints the total count + date range.

- Collapses the **same message only when consecutive** (accidental/stash dups).
- Keeps the same message when it recurs on different days.
- Never collapses generic messages — edit `GENERIC_RE` in the script
  (default matches `fix`, `fixes`, `review fix`, `review fixes`).

### Step 2.5 — preview (optional but recommended)

```bash
bash 2.5-preview.sh
```

Prints a summary (per-repo, per-month histogram, samples) and writes the full
ordered list to `preview.txt`. Nothing is committed. Review it before Step 3.

### Step 3 — generate + push

1. Create a **clean** repo on GitHub and clone it locally:
   ```bash
   git clone git@github.com:you/contribution-history.git ~/contribution-history
   ```
2. Set its author email to one **linked + verified** on your GitHub account
   (Settings → Emails). If the email isn't linked, the squares stay grey.
   ```bash
   cd ~/contribution-history
   git config user.email "you@personal.com"
   ```
3. Point `TARGET_REPO` in `3-generate-commits.sh` at that path (or pass it as an
   argument), then run from the toolkit repo:
   ```bash
   cd /path/to/work-contribution-history
   bash 3-generate-commits.sh                 # or: bash 3-generate-commits.sh /path/to/clean-repo
   ```
4. Verify, then push:
   ```bash
   cd ~/contribution-history
   git log --oneline | wc -l          # matches the record count
   git log --format='%ae' | sort -u   # only your linked email
   git push -u origin main
   ```

The graph updates within minutes to ~24h. Use the year selector on your profile
to see contributions across different years.

---

## Reusing it for future orgs

1. Add any new email/username to the CONFIG block in `1-extract-repo.sh`.
2. Run Step 1 in each new repo (drops new files into `records/`).
3. Re-run `2-combine.sh` and `2.5-preview.sh`.
4. Run `3-generate-commits.sh` into a fresh clean repo (or reset the existing one).

Because everything dedupes on hash, you can keep extracting and re-combining
forever.

---

## Gotchas

- **Full clone first.** A plain `git clone` only fetches the default branch. Use
  `--no-single-branch` (or `git fetch --all`) or you'll miss feature-branch
  commits — and once access is gone, they're gone.
- **Linked email is mandatory.** All replayed commits use one email; it must be
  verified on your GitHub account or nothing turns green.
- **`3-generate-commits.sh` is not idempotent.** Run it once. To redo:
  ```bash
  cd ~/contribution-history
  git update-ref -d refs/heads/main    # wipe all commits
  # re-run Step 3; if already pushed, git push --force
  ```
- **Only your own work.** Capture only commits you actually authored — this keeps
  the history an honest record of your labour, not fabricated activity.
