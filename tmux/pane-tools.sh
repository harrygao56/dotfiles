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
  local quiet="${2:-}"

  "$TMUX_BIN" list-panes -t "$window_id" -F '#{pane_id}' | while IFS= read -r pane_id; do
    "$TMUX_BIN" set-option -p -t "$pane_id" @pane_header_color "$(random_color)" >/dev/null
  done

  if [[ "$quiet" != "quiet" ]]; then
    "$TMUX_BIN" display-message 'Pane headers recolored'
  fi
}

tag_window() {
  local window_id="$1"
  local pane_id path branch

  while IFS=$'\t' read -r pane_id path; do
    branch="$(git -C "$path" symbolic-ref --short HEAD 2>/dev/null || true)"

    if [[ -n "$branch" ]]; then
      "$TMUX_BIN" set-option -p -t "$pane_id" @wt_label "$branch" >/dev/null
    else
      "$TMUX_BIN" set-option -pu -t "$pane_id" @wt_label >/dev/null 2>&1 || true
    fi
  done < <("$TMUX_BIN" list-panes -t "$window_id" -F $'#{pane_id}\t#{pane_current_path}')
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

# tmux's layout-string checksum: a 16-bit rotate-and-add over the body, the
# same algorithm tmux uses internally (layout_checksum in layout-custom.c).
layout_checksum() {
  local s="$1" csum=0 i code
  for ((i = 0; i < ${#s}; i++)); do
    printf -v code '%d' "'${s:i:1}"
    csum=$(( ( (csum >> 1) + ((csum & 1) << 15) + code ) & 0xffff ))
  done
  printf '%04x' "$csum"
}

# Emit one row of the layout: a left-to-right strip of equal-ish columns at a
# given absolute y. A single-pane row is a bare cell (tmux never wraps a lone
# pane in {}); multi-pane rows are wrapped in {}. Columns share the leftover
# width, with the remainder handed to the leftmost columns one cell at a time.
build_row() {
  local width="$1" height="$2" y="$3"
  shift 3
  local ids=("$@")
  local count="${#ids[@]}"

  if (( count == 1 )); then
    printf '%dx%d,0,%d,%s' "$width" "$height" "$y" "${ids[0]}"
    return
  fi

  local avail=$(( width - (count - 1) ))   # 1 column per inter-pane divider
  local base=$(( avail / count ))
  local rem=$(( avail % count ))
  local x=0 cells="" i w
  for ((i = 0; i < count; i++)); do
    w="$base"
    (( i < rem )) && w=$(( w + 1 ))
    cells+="${w}x${height},${x},${y},${ids[i]}"
    x=$(( x + w + 1 ))
    (( i < count - 1 )) && cells+=","
  done
  printf '%dx%d,0,%d{%s}' "$width" "$height" "$y" "$cells"
}

# Rebalance a window into an even grid of at most two rows: 1 pane fills the
# window, 2 panes sit side-by-side in a single row, and 3+ panes split into a
# top row (ceil(n/2)) over a bottom row (floor(n/2)). Panes keep their order.
rebalance() {
  local window_id="$1"
  local quiet="${2:-}"
  local dims
  dims="$("$TMUX_BIN" display-message -p -t "$window_id" '#{window_width} #{window_height}')"
  local width="${dims% *}" height="${dims#* }"

  local ids=()
  local id
  while IFS= read -r id; do
    ids+=("${id#%}")   # layout strings use the bare pane number, no leading %
  done < <("$TMUX_BIN" list-panes -t "$window_id" -F '#{pane_id}')
  local count="${#ids[@]}"

  local body
  if (( count <= 2 )); then
    # One row spanning the full height (a lone pane comes back as a bare cell).
    body="$(build_row "$width" "$height" 0 "${ids[@]}")"
  else
    local top_n=$(( (count + 1) / 2 ))
    local top_h=$(( (height - 1) / 2 ))   # 1 row for the divider between rows
    local bottom_h=$(( height - 1 - top_h ))
    local top_row bottom_row
    top_row="$(build_row "$width" "$top_h" 0 "${ids[@]:0:top_n}")"
    bottom_row="$(build_row "$width" "$bottom_h" "$(( top_h + 1 ))" "${ids[@]:top_n}")"
    body="${width}x${height},0,0[${top_row},${bottom_row}]"
  fi

  "$TMUX_BIN" select-layout -t "$window_id" "$(layout_checksum "$body"),${body}"
  if [[ "$quiet" != "quiet" ]]; then
    "$TMUX_BIN" display-message 'Panes rebalanced'
  fi
}

organize_window() {
  local window_id="$1"

  tag_window "$window_id"
  rebalance "$window_id" quiet
}

refresh_window() {
  local window_id="$1"

  tag_window "$window_id"
  recolor_window "$window_id" quiet
  rebalance "$window_id" quiet
  "$TMUX_BIN" display-message 'Pane indexes, labels, colors, and layout refreshed'
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
    refresh-window)
      refresh_window "$2"
      ;;
    organize-window)
      organize_window "$2"
      ;;
    swap-with-mark)
      swap_with_mark "$2"
      ;;
    rebalance)
      rebalance "$2"
      ;;
    *)
      printf 'Unknown command: %s\n' "$command" >&2
      exit 1
      ;;
  esac
}

main "$@"
