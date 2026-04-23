#!/usr/bin/env bash
set -euo pipefail

TMUX_BIN="${TMUX_BIN:-tmux}"
PALETTE=(
  '#e06c75'
  '#d19a66'
  '#e5c07b'
  '#98c379'
  '#56b6c2'
  '#61afef'
  '#c678dd'
  '#7fbbb3'
  '#ff9e64'
  '#a3be8c'
)

get_global_option() {
  local name="$1"
  "$TMUX_BIN" show-options -gqv "$name" 2>/dev/null || true
}

get_pane_option() {
  local pane_id="$1"
  local name="$2"
  "$TMUX_BIN" show-options -pqv -t "$pane_id" "$name" 2>/dev/null || true
}

pane_exists() {
  local pane_id="$1"
  "$TMUX_BIN" display-message -p -t "$pane_id" '#{pane_id}' >/dev/null 2>&1
}

random_color() {
  local idx=$((RANDOM % ${#PALETTE[@]}))
  printf '%s\n' "${PALETTE[$idx]}"
}

assign_color() {
  local pane_id="$1"
  local current_color
  current_color="$(get_pane_option "$pane_id" @pane_header_color)"

  if [[ -n "$current_color" ]]; then
    return 0
  fi

  "$TMUX_BIN" set-option -p -t "$pane_id" @pane_header_color "$(random_color)" >/dev/null
}

assign_all_colors() {
  "$TMUX_BIN" list-panes -a -F '#{pane_id}' | while IFS= read -r pane_id; do
    assign_color "$pane_id"
  done
}

recolor_window() {
  local window_id="$1"

  "$TMUX_BIN" list-panes -t "$window_id" -F '#{pane_id}' | while IFS= read -r pane_id; do
    "$TMUX_BIN" set-option -p -t "$pane_id" @pane_header_color "$(random_color)" >/dev/null
  done

  "$TMUX_BIN" display-message 'Pane headers recolored'
}

clear_swap_mark() {
  "$TMUX_BIN" set-option -gu @swap_marked_pane >/dev/null 2>&1 || true
}

swap_with_mark() {
  local current_pane="$1"
  local marked_pane

  marked_pane="$(get_global_option @swap_marked_pane)"

  if [[ -z "$marked_pane" ]]; then
    "$TMUX_BIN" set-option -g @swap_marked_pane "$current_pane" >/dev/null
    "$TMUX_BIN" display-message 'Pane marked for swap; move to another pane and press prefix + Shift-S again'
    return 0
  fi

  if ! pane_exists "$marked_pane"; then
    "$TMUX_BIN" set-option -g @swap_marked_pane "$current_pane" >/dev/null
    "$TMUX_BIN" display-message 'Previous marked pane no longer exists; marked current pane instead'
    return 0
  fi

  if [[ "$marked_pane" == "$current_pane" ]]; then
    clear_swap_mark
    "$TMUX_BIN" display-message 'Cleared pane swap mark'
    return 0
  fi

  "$TMUX_BIN" swap-pane -s "$marked_pane" -t "$current_pane"
  clear_swap_mark
  "$TMUX_BIN" display-message 'Panes swapped'
}

main() {
  local command="${1:-}"

  case "$command" in
    assign-color)
      assign_color "$2"
      ;;
    assign-all-colors)
      assign_all_colors
      ;;
    recolor-window)
      recolor_window "$2"
      ;;
    swap-with-mark)
      swap_with_mark "$2"
      ;;
    *)
      printf 'Unknown command: %s\n' "$command" >&2
      exit 1
      ;;
  esac
}

main "$@"
