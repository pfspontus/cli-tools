#!/usr/bin/env bash
# usage:
#   ./new-from-template.sh <repo-url> [branch] <new-folder> [--no-spb] [--create-branches=b1,b2,...]

set -e

REPO_URL=$1
SECOND=$2
THIRD=$3

if [[ -z "$REPO_URL" || -z "$SECOND" ]]; then
  echo "Usage: $0 <repo-url> [branch] <new-folder> [--no-spb] [--create-branches=b1,b2,...]"
  exit 1
fi

# default-värden
BRANCH="main"
NEW_DIR=""
EXTRA_BRANCHES=("staging" "production")

# räkna ut om SECOND är branch eller folder
if [[ -n "$THIRD" && "$THIRD" != --* ]]; then
  # ./script repo branch folder ...
  BRANCH="$SECOND"
  NEW_DIR="$THIRD"
  shift 3
else
  # ./script repo folder ...
  NEW_DIR="$SECOND"
  shift 2
fi

# parsa flaggor
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-spb)
      EXTRA_BRANCHES=()
      ;;
    --create-branches=*)
      IFS=',' read -r -a EXTRA_BRANCHES <<< "${1#--create-branches=}"
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$NEW_DIR"
rm -rf "$NEW_DIR/.git"

cd "$NEW_DIR"
git init
git add .
git commit -m "Initial commit from $BRANCH template"

# skapa extra brancher
for b in "${EXTRA_BRANCHES[@]}"; do
  git branch "$b"
done

echo "✅ Created new repo in '$NEW_DIR' from branch '$BRANCH'"
if ((${#EXTRA_BRANCHES[@]})); then
  echo "  - created branches: ${EXTRA_BRANCHES[*]}"
else
  echo "  - no extra branches"
fi
