# Q.zsh — source-safe cq_* command palette (functions + scripts)
#
# This file is meant to be SOURCED from your interactive zsh so it can see cq_* functions:
#   source ~/.config/zsh/Q.zsh
#
# It defines:
#   - Q: main entry (supports subcommands for testing)
#   - Q_widget: optional zle widget for inserting templates into BUFFER
#
# It DOES NOT autorun at shell startup.

# ----------------------------
# Config (override via env vars)
# ----------------------------
: "${Q_PREFIX:=cq_}"
: "${Q_EXTRA_DIRS:=}"                         # colon-separated extra dirs to scan for scripts
: "${Q_DESC_JOIN:= · }"                       # joiner for multiple desc tags
: "${Q_META_JOIN:= · }"                       # joiner between desc and usage in display
: "${Q_DEFAULT_PLACEHOLDER:=(no description)}"

: "${Q_FZF_CMD:=fzf}"
: "${Q_FZF_OPTS:=--delimiter=$'\t' --with-nth=1 --nth=1,2 --layout=reverse --border}"

: "${Q_ENABLE_PREVIEW:=0}"

# ----------------------------
# Helpers (NO exit, only return)
# ----------------------------
Q_has() { command -v -- "$1" >/dev/null 2>&1; }
Q_err() { print -r -- "Q: $*" >&2; }
Q_die() { Q_err "$*"; return 1; }

Q_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  print -r -- "$s"
}
Q_lower() { print -r -- "${(L)1}"; }

Q_bool() {
  local v; v="$(Q_lower "$(Q_trim "${1:-}")")"
  case "$v" in
    1|true|yes|y|on)  print -r -- "true" ;;
    0|false|no|n|off|"") print -r -- "false" ;;
    *) print -r -- "false" ;;
  esac
}

Q_join() {
  local delim="$1"; shift
  local -a arr; arr=("$@")
  local out="" i
  for i in "${arr[@]}"; do
    [[ -z "$i" ]] && continue
    if [[ -z "$out" ]]; then out="$i"; else out+="${delim}${i}"; fi
  done
  print -r -- "$out"
}

Q_help() {
  cat <<'EOF'
Q — cq_* command palette with metadata parsing and fzf (source-safe).

USAGE
  Q [ARGS...]
    Open fzf picker, then:
      - if #:no-args:true => execute selected command with ARGS...
      - else              => print template "name usage" (or "name ") to stdout

TESTING / SUBCOMMANDS
  Q --help
  Q --parse-function NAME
  Q --parse-file PATH
  Q --collect-functions
  Q --collect-scripts
  Q --dump-index
  Q --dump-fzf-input
  Q --select NAME -- [ARGS...]
  Q --test

ENV
  Q_PREFIX            default: cq_
  Q_EXTRA_DIRS        colon-separated extra dirs scanned for scripts
  Q_ENABLE_PREVIEW    1 enables preview (only works if this file is also executable; see notes)
  Q_FZF_CMD           default: fzf
  Q_FZF_OPTS          default includes two-column display + matching across both columns

NOTES
  - To see interactive cq_* functions, SOURCE this file from your zshrc.
  - Q_widget (optional) inserts Q's template output into the command line BUFFER.
EOF
}

# ----------------------------
# Metadata parsing (unit-testable)
# Output: key=value lines: desc=..., usage=..., no_args=true|false
# ----------------------------

Q_parse_metadata_from_lines() {
  local -a desc_parts=()
  local usage="" no_args="false"
  local raw line payload key val

  while IFS= read -r raw; do
    line="$(Q_trim "$raw")"
    [[ -z "$line" ]] && continue

    # If it's a function no-op metadata line like:
    #   : "#:desc: ..."
    #   : '#:usage: ...'
    # Extract the quoted payload if it contains "#:"
    if [[ "$line" == :\ * && "$line" == *"#:"* ]]; then
      payload=""

      # Try double quotes
      if [[ "$line" == *\"*\"* ]]; then
        payload="${line#*\"}"
        payload="${payload%%\"*}"
      # Try single quotes
      elif [[ "$line" == *\'*\'* ]]; then
        payload="${line#*\'}"
        payload="${payload%%\'*}"
      fi

      if [[ -n "$payload" ]]; then
        line="$(Q_trim "$payload")"
      fi
    fi

    # Allow plain comments (ignore) but keep scanning the header
    if [[ "$line" == \#* && "$line" != \#:* ]]; then
      continue
    fi

    # Parse tag lines
    if [[ "$line" == \#:* ]]; then
      key="${line#\#:}"
      key="${key%%:*}"
      val="${line#\#:${key}:}"
      val="$(Q_trim "$val")"

      case "$key" in
        desc)    desc_parts+=("$val") ;;
        usage)   usage="$val" ;;
        no-args) no_args="$(Q_bool "$val")" ;;
        *)       : ;;
      esac
      continue
    fi

    # Stop at first real code line (or first non-metadata non-comment line)
    break
  done

  local desc; desc="$(Q_join "$Q_DESC_JOIN" "${desc_parts[@]}")"
  print -r -- "desc=$desc"
  print -r -- "usage=$usage"
  print -r -- "no_args=$no_args"
}

Q_parse_metadata_from_file() {
  local path="$1"
  [[ -r "$path" ]] || return 1
  Q_parse_metadata_from_lines < "$path"
}

Q_parse_metadata_from_function() {
  local fn="$1"
  typeset -f "$fn" >/dev/null 2>&1 || return 1

  # feed function body (minus signature line) to parser
  local def after
  def="$(typeset -f "$fn")"
  after="${def#*$'\n'}"
  print -r -- "$after" | Q_parse_metadata_from_lines
}

# ----------------------------
# Discovery (unit-testable)
# ----------------------------
Q_collect_functions() {
  local -a names; names=(${(k)functions})
  local fn
  for fn in "${names[@]}"; do
    [[ "$fn" == ${Q_PREFIX}* ]] && print -r -- "$fn"
  done
}

Q_collect_script_paths() {
  local -a dirs; dirs=(${(s/:/)PATH})
  [[ -n "$Q_EXTRA_DIRS" ]] && dirs+=(${(s/:/)Q_EXTRA_DIRS})

  local -A seen=()
  local dir p
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    local -a cands; cands=("$dir"/${Q_PREFIX}*(N))
    for p in "${cands[@]}"; do
      [[ -f "$p" && -x "$p" ]] || continue
      [[ -n "${seen[$p]:-}" ]] && continue
      seen[$p]=1
      print -r -- "$p"
    done
  done
}

# ----------------------------
# Index storage
# ----------------------------
typeset -gA Q_IDX_source_type Q_IDX_source_path Q_IDX_desc Q_IDX_usage Q_IDX_no_args
Q_index_reset() { Q_IDX_source_type=(); Q_IDX_source_path=(); Q_IDX_desc=(); Q_IDX_usage=(); Q_IDX_no_args=(); }

Q_index_put() {
  local n="$1" t="$2" p="$3" d="$4" u="$5" na="$6"
  Q_IDX_source_type[$n]="$t"
  Q_IDX_source_path[$n]="$p"
  Q_IDX_desc[$n]="$d"
  Q_IDX_usage[$n]="$u"
  Q_IDX_no_args[$n]="$na"
}

Q_build_index() {
  Q_index_reset

  local -A m
  local sp name

  # scripts first
  while IFS= read -r sp; do
    name="${sp:t}"
    m=()
    while IFS='=' read -r k v; do
      m[$k]="$v"
    done < <(Q_parse_metadata_from_file "$sp" 2>/dev/null || true)

    Q_index_put "$name" "script" "$sp" "${m[desc]:-}" "${m[usage]:-}" "${m[no_args]:-false}"
  done < <(Q_collect_script_paths)

  # functions override scripts
  local fn
  while IFS= read -r fn; do
    m=()
    while IFS='=' read -r k v; do
      m[$k]="$v"
    done < <(Q_parse_metadata_from_function "$fn" 2>/dev/null || true)

    Q_index_put "$fn" "function" "<function>" "${m[desc]:-}" "${m[usage]:-}" "${m[no_args]:-false}"
  done < <(Q_collect_functions)

  return 0
}


Q_dump_index() {
  Q_build_index || return 1
  local name
  for name in ${(on)${(k)Q_IDX_source_type}}; do
    print -r -- "$name | ${Q_IDX_source_type[$name]} | no-args=${Q_IDX_no_args[$name]} | desc=${Q_IDX_desc[$name]} | usage=${Q_IDX_usage[$name]} | src=${Q_IDX_source_path[$name]}"
  done
}

# ----------------------------
# fzf input + selection
# ----------------------------
Q_build_fzf_lines() {
  local dim=$'\e[90m'
  local reset=$'\e[0m'

  local name desc usage search
  for name in ${(on)${(k)Q_IDX_source_type}}; do
    desc="${Q_IDX_desc[$name]}"
    usage="${Q_IDX_usage[$name]}"

    search=""
    if [[ -n "$desc" && -n "$usage" ]]; then
      search="${desc}${Q_META_JOIN}${usage}"
    elif [[ -n "$desc" ]]; then
      search="$desc"
    elif [[ -n "$usage" ]]; then
      search="$usage"
    fi

    # name<TAB><dim>metadata<reset><NL>
    # adding spaces to move metadata away from command name for better visibility
    printf '%s\t        %s%s%s\n' "$name" "$dim" "$search" "$reset"
  done
}

Q_dump_fzf_input() {
  Q_build_index || return 1
  Q_build_fzf_lines
}

Q_command_template_for() {
  local name="$1"
  print -r -- "$name "
}

Q_usage_for() {
  local name="$1"
  print -r -- "${Q_IDX_usage[$name]:-}"
}

Q_execute_or_template() {
  local name="$1"; shift
  [[ -n "${Q_IDX_source_type[$name]:-}" ]] || return 1

  # Only treat literal "true" as true
  local no_args="${Q_IDX_no_args[$name]:-false}"
  if [[ "$no_args" == "true" ]]; then
    "$name" "$@"
    return $?
  fi

  Q_command_template_for "$name"
}

Q_run_fzf() {
  Q_has "$Q_FZF_CMD" || return 1

  local cache preview
  cache="$(Q_make_preview_cache)" || return 1
  preview="$(mktemp -t q-preview-cmd.XXXXXX)" || { rm -f -- "$cache"; return 1; }

  cat >| "$preview" <<'SH'
#!/bin/sh
cache="$1"
name="$2"
awk -F '\t' -v n="$name" '
  $1==n {
    na = ($5=="true" ? "True" : "False");
    printf "%s: %s\nDescription: %s\nUsage: %s\nNo arguments: %s\n", $2, $1, $3, $4, na;
    exit
  }
' "$cache"
SH

  chmod +x "$preview" 2>/dev/null || true

  local -a opts
  opts=(
    --ansi
    --delimiter $'\t'
    --with-nth 1,2
    --nth 1,2
    --layout reverse
    --border
    --preview-window right:60%:wrap
    --preview "$preview $cache {1}"
  )

  local chosen rc
chosen="$(
  Q_build_fzf_lines | env -i PATH="$PATH" HOME="$HOME" TERM="$TERM" LANG="$LANG" \
    "$Q_FZF_CMD" "${opts[@]}"
)"
  rc=$?
  rm -f -- "$cache" "$preview" 2>/dev/null || true
  (( rc == 0 )) || return $rc
  print -r -- "$chosen"

}

# Define the function normally
Q_preview_line() {
  emulate -L zsh
  local cache="$1"
  local name="$2"

  local line
  line="$(command rg --fixed-strings --no-heading --color=never "^${name}"$'\t' "$cache" 2>/dev/null | head -n1)" || return 0

  local n type desc usage no_args
  IFS=$'\t' read -r n type desc usage no_args <<<"$line"

  local na_disp="False"
  [[ "$no_args" == "true" ]] && na_disp="True"

  print -r -- "(${type}): ${n}"
  print -r -- "Description: ${desc}"
  print -r -- "Usage: ${usage}"
  print -r -- "No arguments: ${na_disp}"
}

Q_make_preview_cache() {
  local cache
  cache="$(mktemp -t q-preview.XXXXXX)" || return 1

  local name
  for name in ${(on)${(k)Q_IDX_source_type}}; do
    print -r -- \
      "$name"$'\t'"${Q_IDX_source_type[$name]}"$'\t'"${Q_IDX_desc[$name]}"$'\t'"${Q_IDX_usage[$name]}"$'\t'"${Q_IDX_no_args[$name]}"
  done >| "$cache"

  print -r -- "$cache"
}

Q_preview_from_cache() {
  local cache="$1"
  local name="$2"
  local line

  line="$(rg --fixed-strings --no-heading --color=never "^${name}"$'\t' "$cache" 2>/dev/null | head -n1)" || true
  [[ -n "$line" ]] || return 0

  local n type desc usage no_args
  IFS=$'\t' read -r n type desc usage no_args <<<"$line"

  # Capitalize boolean for display
  local na_disp="False"
  [[ "$no_args" == "true" ]] && na_disp="True"

  print -r -- "(${type}): ${n}"
  print -r -- "Description: ${desc}"
  print -r -- "Usage: ${usage}"
  print -r -- "No arguments: ${na_disp}"
}


# ----------------------------
# Tests (simple sanity; return codes only)
# ----------------------------
Q_assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" != "$want" ]]; then
    Q_err "ASSERT FAIL: $msg"
    Q_err "  got:  $got"
    Q_err "  want: $want"
    return 1
  fi
  return 0
}

Q_run_tests() {
  local tmp; tmp="$(mktemp -d)" || return 1
  local fail=0

  local s1="$tmp/cq_script1"
  cat > "$s1" <<'EOF'
#!/usr/bin/env bash
#:desc: Script one
#:usage: cq_script1 <x>
#:no-args: false

echo "hi"
EOF
  chmod +x "$s1"

  local meta desc usage no_args
  meta="$(Q_parse_metadata_from_file "$s1" || true)"
  desc="${meta[(r)desc=*]#desc=}"
  usage="${meta[(r)usage=*]#usage=}"
  no_args="${meta[(r)no_args=*]#no_args=}"

  Q_assert_eq "$desc" "Script one" "parse desc from file" || fail=1
  Q_assert_eq "$usage" "cq_script1 <x>" "parse usage from file" || fail=1
  Q_assert_eq "$no_args" "false" "parse no-args from file" || fail=1

  rm -rf "$tmp"
  (( fail == 0 )) || return 1
  print -r -- "Q tests: OK"
  return 0
}

# ----------------------------
# Main dispatcher (THIS is what makes subcommands work)
# ----------------------------
Q_main() {
  emulate -L zsh
  # stop startup/debug tracing from polluting stdout
  set +x 2>/dev/null || true
  unsetopt xtrace 2>/dev/null || true
  XTRACEFD=2

  local mode="run"
  local parse_file=""
  local parse_fn=""
  local select_name=""
  local -a pass_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h) mode="help"; shift ;;
      --parse-file) mode="parse_file"; shift; parse_file="${1:-}"; shift ;;
      --parse-function) mode="parse_fn"; shift; parse_fn="${1:-}"; shift ;;
      --collect-functions) mode="collect_functions"; shift ;;
      --collect-scripts) mode="collect_scripts"; shift ;;
      --dump-index) mode="dump_index"; shift ;;
      --dump-fzf-input) mode="dump_fzf"; shift ;;
      --select) mode="select"; shift; select_name="${1:-}"; shift ;;
      --test) mode="test"; shift ;;
      --) shift; pass_args+=("$@"); break ;;
      *) pass_args+=("$1"); shift ;;
    esac
  done

  case "$mode" in
    help)
      Q_help
      return 0
      ;;
    parse_file)
      [[ -n "$parse_file" ]] || return 1
      Q_parse_metadata_from_file "$parse_file" || Q_die "failed to parse file: $parse_file"
      ;;
    parse_fn)
      [[ -n "$parse_fn" ]] || return 1
      Q_parse_metadata_from_function "$parse_fn" || Q_die "failed to parse function: $parse_fn"
      ;;
    collect_functions)
      Q_collect_functions
      ;;
    collect_scripts)
      Q_collect_script_paths
      ;;
    dump_index)
      Q_dump_index
      ;;
    dump_fzf)
      Q_dump_fzf_input
      ;;
    select)
      [[ -n "$select_name" ]] || return 1
      Q_build_index
      Q_execute_or_template "$select_name" "${pass_args[@]}" || return 1
      ;;
    test)
      Q_run_tests
      ;;
    run)
      Q_build_index || return 1
      (( ${#Q_IDX_source_type} > 0 )) || { Q_err "no ${Q_PREFIX}* commands found"; return 1; }

      local chosen name
      chosen="$(Q_run_fzf)" || return 1
      [[ -n "$chosen" ]] || return 1

      name="${chosen%%$'\t'*}"
      Q_execute_or_template "$name" "${pass_args[@]}"
      ;;
  esac
}

Q_widget() {
  emulate -L zsh
  set +x 2>/dev/null || true
  unsetopt xtrace 2>/dev/null || true
  XTRACEFD=2

  local chosen name
  Q_build_index || return
  chosen="$(Q_run_fzf)" || return
  [[ -n "$chosen" ]] || return
  name="${chosen%%$'\t'*}"

  local no_args="${Q_IDX_no_args[$name]:-false}"
  if [[ "$no_args" == "true" ]]; then
    "$name"
    zle redisplay
    return
  fi

  local u
  u="$(Q_usage_for "$name")"

  BUFFER="$(Q_command_template_for "$name")"
  CURSOR=${#BUFFER}
zle reset-prompt
  [[ -n "$u" ]] && zle -M "$u"
}

Q() {
  # If user asked for a subcommand/flag mode, run the dispatcher.
  # (Add/remove flags here if you add more.)
  local a
  for a in "$@"; do
    case "$a" in
      --help|-h|--dump-index|--dump-fzf-input|--collect-functions|--collect-scripts|--parse-file|--parse-function|--select|--test|--)
        Q_main "$@"
        return $?
        ;;
    esac
  done

  # Interactive keybinding path (ZLE): do the good UX
  if [[ -o interactive ]] && zle; then
    zle Q_widget
    return $?
  fi

  # Non-ZLE (typed "Q"): run picker and print guidance
  emulate -L zsh
  unsetopt xtrace 2>/dev/null || true

  Q_build_index || return 1
  local chosen name
  chosen="$(Q_run_fzf)" || return 1
  [[ -n "$chosen" ]] || return 1
  name="${chosen%%$'\t'*}"

  local no_args="${Q_IDX_no_args[$name]:-false}"
  if [[ "$no_args" == "true" ]]; then
    "$name"
    return $?
  fi

  local usage="${Q_IDX_usage[$name]:-}"
  [[ -n "$usage" ]] && print -ru2 -- "$usage"

  # Queue the command for editing at the prompt (best possible outside ZLE)
  print -z -- "$name "
}

