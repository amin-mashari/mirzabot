#!/usr/bin/env bash
#
# Pulls the latest changes from the official upstream repo (mahdiMGF2/mirzabot)
# and merges them into main, then pushes the result to your private fork
# (origin), without losing your own commits (TonPays gateway, web-panel
# work, etc.). Mirrors the logic in .github/workflows/sync-upstream.yml but
# runs locally.
#
# Usage: ./fetch.sh
set -euo pipefail

UPSTREAM_URL="https://github.com/mahdiMGF2/mirzabot.git"
MAIN_BRANCH="main"

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: you have uncommitted changes. Commit or stash them first, then rerun." >&2
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "Adding upstream remote ($UPSTREAM_URL)..."
  git remote add upstream "$UPSTREAM_URL"
fi

echo "Fetching upstream..."
git fetch upstream "$MAIN_BRANCH"

echo "Fetching origin..."
git fetch origin "$MAIN_BRANCH"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
git checkout "$MAIN_BRANCH"
git pull --ff-only origin "$MAIN_BRANCH"

SYNC_BRANCH="sync/upstream-$(date +%Y-%m-%d-%H%M%S)"
git checkout -b "$SYNC_BRANCH"

if git merge "upstream/$MAIN_BRANCH" --no-edit -m "Merge upstream/$MAIN_BRANCH into $MAIN_BRANCH"; then
  if git diff --quiet "$MAIN_BRANCH" "$SYNC_BRANCH"; then
    echo "Already up to date with upstream; nothing to push."
    git checkout "$MAIN_BRANCH"
    git branch -d "$SYNC_BRANCH"
  else
    git checkout "$MAIN_BRANCH"
    git merge --ff-only "$SYNC_BRANCH"
    git branch -d "$SYNC_BRANCH"
    echo "Pushing merged $MAIN_BRANCH to origin..."
    git push origin "$MAIN_BRANCH"
    echo "Done: upstream changes merged into $MAIN_BRANCH and pushed to origin."
  fi
else
  echo
  echo "Merge conflicts detected. Your changes are safe — nothing was pushed."
  echo "Conflict markers were left in place on branch '$SYNC_BRANCH'."
  echo "Resolve them there, commit, then merge into $MAIN_BRANCH and push yourself:"
  echo "  git status"
  echo "  # fix conflicts, then:"
  echo "  git add -A && git commit"
  echo "  git checkout $MAIN_BRANCH && git merge $SYNC_BRANCH && git push origin $MAIN_BRANCH"
  exit 1
fi

git checkout "$CURRENT_BRANCH" >/dev/null 2>&1 || true
