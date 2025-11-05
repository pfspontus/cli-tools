#!/usr/bin/env bash
# usage: ./rollback-deploy.sh [--prefix=release-] [staging|production]

set -e

PREFIX=""
ENV="staging"

# parsa ev. prefix
for arg in "$@"; do
  case "$arg" in
    --prefix=*)
      PREFIX="${arg#--prefix=}"
      ;;
    staging|production)
      ENV="$arg"
      ;;
  esac
done

if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
  echo "❌ env must be 'staging' or 'production'"
  exit 1
fi

git fetch --tags

# hämta alla taggar (ev. filtrerade) och sortera
if [ -n "$PREFIX" ]; then
  TAGS=($(git tag --list "${PREFIX}*" | sort -V))
else
  TAGS=($(git tag --list | sort -V))
fi

NUM=${#TAGS[@]}
if [ "$NUM" -lt 2 ]; then
  echo "❌ Not enough tags to rollback."
  exit 1
fi

# näst sista = rollback-target
ROLLBACK_TAG=${TAGS[$((NUM-2))]}

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Rolling back $ENV to $ROLLBACK_TAG ..."
git checkout "$ENV"
git reset --hard "$ROLLBACK_TAG"

if git remote get-url origin >/dev/null 2>&1; then
  git push -f origin staging
  echo "Pushed staging to origin"
fi

git checkout "$CURRENT_BRANCH"

echo "✅ $ENV is now at $ROLLBACK_TAG (returned to $CURRENT_BRANCH)"
