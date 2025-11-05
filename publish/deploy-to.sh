#!/usr/bin/env bash
# usage:
#   ./deploy-to.sh [tag] [env]
#   ./deploy-to.sh --prefix=release- [env]

set -e

TAG=""
ENV=""
PREFIX=""

# enkel flagg-parsning
for arg in "$@"; do
  case "$arg" in
    --prefix=*)
      PREFIX="${arg#--prefix=}"
      shift
      ;;
  esac
done

# efter ev. prefix är borttaget: första kvarvarande kan vara tag eller env
if [ $# -ge 1 ]; then
  TAG=$1
fi
if [ $# -ge 2 ]; then
  ENV=$2
fi

# om första var env (staging/production)
if [[ "$TAG" == "staging" || "$TAG" == "production" ]]; then
  ENV=$TAG
  TAG=""
fi

ENV=${ENV:-staging}

if [ -z "$TAG" ]; then
  # hämta senaste taggen, ev. filtrerad
  if [ -n "$PREFIX" ]; then
    TAG=$(git tag --list "${PREFIX}*" | sort -V | tail -1)
  else
    TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")
  fi
fi

if [ -z "$TAG" ]; then
  echo "❌ No tags found."
  exit 1
fi

if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
  echo "❌ env must be 'staging' or 'production'"
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

git fetch --tags

git checkout "$ENV"
git reset --hard "$TAG"

if git remote get-url origin >/dev/null 2>&1; then
  git push -f origin staging
  echo "Pushed staging to origin"
fi

git checkout "$CURRENT_BRANCH"

echo "✅ $ENV is now at $TAG (returned to $CURRENT_BRANCH)"
