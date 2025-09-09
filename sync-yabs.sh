#!/usr/bin/env bash

set -euo pipefail

DEFAULT_REMOTE_URL="https://github.com/masonr/yet-another-bench-script.git"
DEFAULT_BRANCH="master"
DEFAULT_PREFIX="src/"
DEFAULT_MESSAGE="chore: sync src from upstream"

REMOTE_URL="$DEFAULT_REMOTE_URL"
BRANCH="$DEFAULT_BRANCH"
PREFIX="$DEFAULT_PREFIX"
COMMIT_MESSAGE="$DEFAULT_MESSAGE"
USE_SQUASH=true
ALLOW_DIRTY=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Pull latest upstream into the git subtree at prefix (default: src/).

Exit codes:
  0 = ran successfully (changes may or may not have been applied)
  1 = error (pull failed and no diffs detected)

Machine-readable output:
  Prints a line 'changed=true' or 'changed=false' to stdout.

Options:
  --remote-url <url>   Upstream repo URL (default: $DEFAULT_REMOTE_URL)
  --branch <name>      Upstream branch (default: $DEFAULT_BRANCH)
  --prefix <path>      Subtree prefix (default: $DEFAULT_PREFIX)
  --message <msg>      Commit message (default: "$DEFAULT_MESSAGE")
  --no-squash          Do not squash subtree history (default: squash)
  --allow-dirty        Allow running with uncommitted changes (default: false)
  -h, --help           Show this help and exit

Environment:
  Set GIT_TRACE=1 for verbose git output if troubleshooting.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote-url)
      REMOTE_URL="$2"; shift 2 ;;
    --branch)
      BRANCH="$2"; shift 2 ;;
    --prefix)
      PREFIX="$2"; shift 2 ;;
    --message)
      COMMIT_MESSAGE="$2"; shift 2 ;;
    --no-squash)
      USE_SQUASH=false; shift ;;
    --allow-dirty)
      ALLOW_DIRTY=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2 ;;
  esac
done

# Ensure we're running inside a git repo and at repo root
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository" >&2
  exit 2
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ "$ALLOW_DIRTY" != true ]]; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: working tree has uncommitted changes. Commit or stash, or pass --allow-dirty." >&2
    exit 2
  fi
fi

# Check required tools
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git not found in PATH" >&2
  exit 2
fi

# Fetch upstream (prefer an 'upstream' remote if configured)
upstream_ref="$REMOTE_URL"
if git remote get-url upstream >/dev/null 2>&1; then
  upstream_ref="upstream"
  git fetch upstream --tags --prune
else
  # When using a URL directly, perform a manual fetch for freshness
  git fetch "$REMOTE_URL" "$BRANCH" --tags --prune || true
fi

before_commit=$(git rev-parse HEAD)

squash_flag=( )
if [[ "$USE_SQUASH" == true ]]; then
  squash_flag=("--squash")
fi

# Attempt subtree pull
set +e
git subtree pull --prefix="$PREFIX" "$upstream_ref" "$BRANCH" "${squash_flag[@]}" -m "$COMMIT_MESSAGE"
pull_rc=$?
set -e

after_commit=$(git rev-parse HEAD)

if [[ $pull_rc -eq 0 ]]; then
  # Success return from git subtree; verify if something actually changed
  if [[ "$before_commit" != "$after_commit" ]] || ! git diff --quiet; then
    echo "Subtree updated: changes applied to $PREFIX"
    echo "changed=true"
    exit 0
  else
    echo "No changes detected for $PREFIX"
    echo "changed=false"
    exit 0
  fi
else
  # git subtree returned non-zero; check if any diffs resulted
  if ! git diff --quiet; then
    echo "Subtree reported failure, but diffs detected. Treating as changed."
    echo "changed=true"
    exit 0
  fi
  echo "Subtree pull failed and no diffs detected."
  exit 1
fi


