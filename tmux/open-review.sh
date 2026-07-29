#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"

case "$mode" in
  edit)
    exec nvim .
    ;;
  diff)
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      printf 'Not inside a git worktree.\n' >&2
      exit 1
    fi

    if ! base="$(git merge-base origin/main HEAD)"; then
      printf 'Could not find the merge base of origin/main and HEAD.\n' >&2
      exit 1
    fi

    exec nvim -c "DiffviewOpen ${base}"
    ;;
  *)
    printf 'Usage: %s <edit|diff>\n' "${0##*/}" >&2
    exit 2
    ;;
esac
