#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/collect-context.sh [--base REF] [--pr NUMBER] [--output FILE]

Collects non-secret git and optional GitHub PR context for a Damage Report.
It does not modify source files, commits, branches, or remote state.
EOF
}

BASE_REF=""
PR_NUMBER=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_REF="${2:-}"
      shift 2
      ;;
    --pr)
      PR_NUMBER="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Error: run this script inside a git worktree." >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ -z "$OUTPUT" ]]; then
  OUTPUT=".cursor/damage-reports/context.txt"
fi
mkdir -p "$(dirname "$OUTPUT")"

if [[ -z "$BASE_REF" ]]; then
  DEFAULT_REMOTE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  for candidate in "$DEFAULT_REMOTE" origin/main origin/master main master; do
    if [[ -n "$candidate" ]] && git rev-parse --verify "$candidate^{commit}" >/dev/null 2>&1; then
      BASE_REF="$candidate"
      break
    fi
  done
fi

{
  echo "# Damage Report Context"
  echo
  echo "generated_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repository_root=$ROOT"
  echo "branch=$(git branch --show-current || true)"
  echo "head_sha=$(git rev-parse HEAD)"
  echo "base_ref=${BASE_REF:-unresolved}"
  echo
  echo "## Git status"
  git status --short --branch
  echo
  echo "## Untracked files"
  git ls-files --others --exclude-standard
  echo
  echo "## Staged changes"
  git diff --cached --stat
  git diff --cached --name-status
  echo
  echo "## Unstaged changes"
  git diff --stat
  git diff --name-status

  if [[ -n "$BASE_REF" ]]; then
    MERGE_BASE="$(git merge-base "$BASE_REF" HEAD 2>/dev/null || true)"
    echo
    echo "merge_base=${MERGE_BASE:-unresolved}"
    if [[ -n "$MERGE_BASE" ]]; then
      echo
      echo "## Branch commits"
      git log --oneline --decorate "$MERGE_BASE"..HEAD
      echo
      echo "## Branch diff"
      git diff --stat "$MERGE_BASE"...HEAD
      git diff --name-status "$MERGE_BASE"...HEAD
    fi
  fi

  if [[ -n "$PR_NUMBER" ]]; then
    echo
    echo "## GitHub PR"
    if command -v gh >/dev/null 2>&1; then
      gh pr view "$PR_NUMBER" \
        --json number,url,title,state,isDraft,baseRefName,headRefName,headRefOid,mergeable,reviewDecision,statusCheckRollup \
        2>&1 || echo "Unable to fetch PR metadata."
      echo
      gh pr checks "$PR_NUMBER" 2>&1 || echo "Unable to fetch PR checks."
    else
      echo "gh is not installed; PR context unavailable."
    fi
  fi
} > "$OUTPUT"

echo "Wrote context to $OUTPUT"
