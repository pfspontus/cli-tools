#!/usr/bin/env bash
# usage: ./tag-today.sh <name>

set -e

NAME=$1
if [ -z "$NAME" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

# måste stå på main
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ You must be on 'main' (current: $CURRENT_BRANCH)"
  exit 1
fi

DATE=$(date +%Y-%m-%d)
HEAD_SHA=$(git rev-parse HEAD)

# hitta alla taggar för dagens namn
EXISTING_TAGS=$(git tag | grep "^${NAME}-${DATE}-" || true)

# kolla först om någon av dem pekar på nuvarande commit
if [ -n "$EXISTING_TAGS" ]; then
  for t in $EXISTING_TAGS; do
    TAG_SHA=$(git rev-parse "$t")
    if [ "$TAG_SHA" = "$HEAD_SHA" ]; then
      # taggen finns redan för denna commit → pusha ev. remote och avsluta
      if git remote get-url origin >/dev/null 2>&1; then
        # försök pusha just den taggen, ifall den bara fanns lokalt
        git push origin "$t" >/dev/null 2>&1 || true
      fi
      echo "✅ Tag already exists for this commit: $t"
      exit 0
    fi
  done
fi

# annars: räkna upp sekvens
if [ -z "$EXISTING_TAGS" ]; then
  SEQ=1
else
  LAST_SEQ=$(echo "$EXISTING_TAGS" | sed "s/^${NAME}-${DATE}-//" | sort -n | tail -1)
  SEQ=$((LAST_SEQ + 1))
fi

TAG="${NAME}-${DATE}-${SEQ}"

git tag "$TAG"

if git remote get-url origin >/dev/null 2>&1; then
  git push origin "$TAG"
  echo "✅ Created and pushed tag: $TAG"
else
  echo "✅ Created local tag: $TAG (no remote found)"
fi
