#!/usr/bin/env bash
# usage:
#   ./publish.sh -t                     # skapa publish-tagg
#   ./publish.sh -d [env]               # deploy senaste publish-* till env (staging default)
#   ./publish.sh -t -d [env]            # tagga + deploy
#   ./publish.sh -r [env]               # rollback env till föregående publish-*
#   ./publish.sh -h | --help            # hjälp

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DO_TAG=false
DO_DEPLOY=false
DO_ROLLBACK=false
ENV=staging
PREFIX="publish-"
NAME="publish"

usage() {
  echo "Usage:"
  echo "  $0 -t                     # skapa publish-tagg"
  echo "  $0 -d [staging|production]# deploy senaste publish-*"
  echo "  $0 -t -d [env]            # tagga + deploy"
  echo "  $0 -r [env]               # rollback till föregående publish-*"
  echo "  $0 -h                     # hjälp"
  exit 0
}

if [ $# -eq 0 ]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)
      DO_TAG=true
      shift
      ;;
    -d|--deploy)
      DO_DEPLOY=true
      if [[ -n "${2:-}" && "$2" != -* ]]; then
        ENV="$2"
        shift 2
      else
        shift
      fi
      ;;
    -r|--rollback)
      DO_ROLLBACK=true
      if [[ -n "${2:-}" && "$2" != -* ]]; then
        ENV="$2"
        shift 2
      else
        shift
      fi
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "❌ Unknown arg: $1"
      usage
      ;;
  esac
done

# förhindra tok-kombinationer
if $DO_DEPLOY && $DO_ROLLBACK; then
  echo "❌ Can't deploy and rollback in same command."
  exit 1
fi

if $DO_TAG; then
  "$SCRIPT_DIR/tag-today.sh" "$NAME"
fi

if $DO_DEPLOY; then
  "$SCRIPT_DIR/deploy-to.sh" --prefix="$PREFIX" "$ENV"
fi

if $DO_ROLLBACK; then
  "$SCRIPT_DIR/rollback-deploy.sh" --prefix="$PREFIX" "$ENV"
fi
