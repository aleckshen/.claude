#!/usr/bin/env bash

input=$(cat)

# --- Data extraction ---
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
# Full context token count = input + cache_creation + cache_read (matches what /context reports)
ctx_input_tokens=$(echo "$input" | jq -r '
  if .context_window.current_usage != null then
    ((.context_window.current_usage.input_tokens // 0) +
     (.context_window.current_usage.cache_creation_input_tokens // 0) +
     (.context_window.current_usage.cache_read_input_tokens // 0))
  else empty end')
ctx_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# fmt_resets_at <epoch> <format: hm|dh>
#   hm  → [Xh:XXm]   (5-hour window)
#   dh  → [Xd:XXh]   (7-day window)
fmt_resets_at() {
  local epoch="$1" fmt="${2:-hm}"
  [ -z "$epoch" ] && return
  local now diff
  now=$(date +%s)
  diff=$(( epoch - now ))
  [ "$diff" -le 0 ] && echo "[now]" && return
  if [ "$fmt" = "dh" ]; then
    local days=$(( diff / 86400 ))
    local hours=$(( (diff % 86400) / 3600 ))
    local mins=$(( (diff % 3600) / 60 ))
    printf "[%02dd:%02dh:%02dm]\n" "$days" "$hours" "$mins"
  else
    local hours=$(( diff / 3600 ))
    local mins=$(( (diff % 3600) / 60 ))
    printf "[%dh:%02dm]\n" "$hours" "$mins"
  fi
}

# --- Git branch ---
git_branch=""
if [ -n "$cwd" ] && cd "$cwd" 2>/dev/null; then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git symbolic-ref --short HEAD 2>/dev/null \
    || GIT_OPTIONAL_LOCKS=0 git rev-parse --short HEAD 2>/dev/null)
fi

# --- ANSI colors ---
reset="\033[0m"
bold="\033[1m"
dim="\033[2m"
blink="\033[5m"

color_dir="\033[38;2;136;192;208m"    # soft blue (directory)
color_branch="\033[38;2;235;203;139m" # warm gold (branch)
color_model="\033[97m"                # bright white (model)
color_green="\033[32m"
color_yellow="\033[33m"
color_orange="\033[38;5;208m"
color_red="\033[31m"
color_white="\033[37m"

sep=" │ "

parts=()

# Current working directory
if [ -n "$cwd" ]; then
  cwd_display=$(basename "$cwd")
  parts+=("$(printf "${color_dir}%s${reset}" "$cwd_display")")
fi

# Git branch
if [ -n "$git_branch" ]; then
  parts+=("$(printf "${color_branch}(%s)${reset}" "$git_branch")")
fi

# Context window
if [ -n "$used_pct" ] && [ -n "$remaining_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ "$used_int" -ge 80 ]; then
    ctx_color="${blink}${color_red}"
    skull="💀 "
  elif [ "$used_int" -ge 65 ]; then
    ctx_color="$color_orange"
    skull=""
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$color_yellow"
    skull=""
  else
    ctx_color="$color_green"
    skull=""
  fi
  # Build optional token count annotation (e.g. "90k/200k")
  ctx_tokens_str=""
  if [ -n "$ctx_input_tokens" ] && [ -n "$ctx_window_size" ]; then
    used_k=$(awk "BEGIN { printf \"%.0f\", $ctx_input_tokens / 1000 }")
    total_k=$(awk "BEGIN { printf \"%.0f\", $ctx_window_size / 1000 }")
    ctx_tokens_str="${reset}${dim} (${used_k}k/${total_k}k)"
  fi
  parts+=("$(printf "${dim}ctx${reset} ${ctx_color}${skull}%s%%%s${reset}" "$used_int" "$ctx_tokens_str")")
fi

# 5-hour session limit
if [ -n "$five_hour" ]; then
  pct_int=$(printf '%.0f' "$five_hour")
  if [ "$pct_int" -ge 80 ]; then
    lim_color="$color_red"
  elif [ "$pct_int" -ge 75 ]; then
    lim_color="$color_orange"
  elif [ "$pct_int" -ge 50 ]; then
    lim_color="$color_yellow"
  else
    lim_color="$color_green"
  fi
  resets_str=$(fmt_resets_at "$five_hour_resets" hm)
  reset_suffix=""
  [ -n "$resets_str" ] && reset_suffix="$(printf " ${dim}%s${reset}" "$resets_str")"
  parts+=("$(printf "${dim}5h${reset} ${lim_color}%s%%${reset}%b" "$pct_int" "$reset_suffix")")
fi

# 7-day session limit
if [ -n "$seven_day" ]; then
  pct_int=$(printf '%.0f' "$seven_day")
  if [ "$pct_int" -ge 80 ]; then
    lim_color="$color_red"
  elif [ "$pct_int" -ge 75 ]; then
    lim_color="$color_orange"
  elif [ "$pct_int" -ge 50 ]; then
    lim_color="$color_yellow"
  else
    lim_color="$color_green"
  fi
  resets_str=$(fmt_resets_at "$seven_day_resets" dh)
  reset_suffix=""
  [ -n "$resets_str" ] && reset_suffix="$(printf " ${dim}%s${reset}" "$resets_str")"
  parts+=("$(printf "${dim}7d${reset} ${lim_color}%s%%${reset}%b" "$pct_int" "$reset_suffix")")
fi

# Model
parts+=("$(printf "${color_model}%s${reset}" "$model")")

# Vim mode
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    INSERT)  mode_color="$color_green"  ;;
    NORMAL)  mode_color="$color_yellow" ;;
    *)       mode_color="$color_white"  ;;
  esac
  parts+=("$(printf "${mode_color}${bold}%s${reset}" "$vim_mode")")
fi

# --- Assemble ---
line=""
for part in "${parts[@]}"; do
  if [ -z "$line" ]; then
    line="$part"
  else
    line="${line}${sep}${part}"
  fi
done

printf "%b\n" "$line"
