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
# Extra fzf options, appended LAST so they override the built-ins (fzf: later wins).
# The built-ins already set --ansi --delimiter --with-nth --nth --layout --border
# (plus --preview when Q_ENABLE_PREVIEW=1), so leave this empty unless you want to
# override something. NOTE: the old default here was silently ignored entirely.
: "${Q_FZF_OPTS:=}"

# 1 = show the preview pane. (Documented before, but never actually wired up.)
: "${Q_ENABLE_PREVIEW:=1}"
# How many source lines the preview shows before truncating.
: "${Q_PREVIEW_LINES:=48}"

# ---------------------------------------------------------------------------
# TODO — considered, deferred (raise again if wanted)
#
# 1. Buffer template UX (Q_widget)
#    Currently selects `cq_foo ` (name + trailing space) and prints the usage
#    string as a separate zle message. Alternative: insert the full usage
#    template, e.g. `cq_env_arg <file>`, so placeholders land in the buffer and
#    can be edited in place. Needs a decision on whether placeholders should be
#    auto-selected (zle -I / region highlight) so typing replaces them.
#
# 2. On-disk index cache
#    Index build is ~20ms and the preview cache adds ~5-10ms, so this is NOT
#    currently worth the invalidation complexity. Revisit only if the entry count
#    grows into the hundreds. Sketch: serialise Q_IDX_* to
#    ${XDG_CACHE_HOME:-~/.cache}/q/index.zsh (a zsh-sourceable assoc-array dump),
#    and invalidate on the newest mtime of any scanned dir plus a hash of the
#    cq_* function-name list (functions live in the running shell, so their
#    mtimes don't exist — the name list is the only cheap signal).
#
# 3. Palette naming for scripts with extensions
#    cq_sys_status.py indexes as "cq_sys_status.py" — the extension shows up in
#    the picker. Dropping .py from the filename would give a cleaner entry.
# ---------------------------------------------------------------------------

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
  Q --doctor                  # report entries with missing/incomplete metadata
  Q --dump-fzf-input
  Q --select NAME -- [ARGS...]
  Q --test

  Q_ENABLE_PREVIEW    1 shows the source preview pane (default: 1)
  Q_PREVIEW_LINES     source lines shown before truncating (default: 48)

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
# Metadata parsing
# ----------------------------
# The parser lands its results in these globals rather than printing key=value
# lines that the caller then re-splits. Together with fork-free trimming this
# removed ~2 forks per header line: index build went 294ms -> 11ms (71 entries).
#   Q_P_DESC / Q_P_USAGE / Q_P_NO_ARGS
typeset -g Q_P_DESC="" Q_P_USAGE="" Q_P_NO_ARGS=""

Q_parse_text() {
  emulate -L zsh
  Q_P_DESC=""; Q_P_USAGE=""; Q_P_NO_ARGS=""

  local -a _q_desc=()
  local raw line key val payload out part
  local -a _q_lines; _q_lines=("${(@f)1}")

  for raw in "${_q_lines[@]}"; do
    # trim in pure zsh (no $(Q_trim ...) subshell)
    line="${raw#"${raw%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue

    # Function metadata is written as a no-op so the comment is also *data* at
    # runtime, e.g.   : "#:desc: ..."   — unwrap the quoted payload.
    if [[ "$line" == :\ * && "$line" == *"#:"* ]]; then
      payload=""
      if [[ "$line" == *\"*\"* ]]; then
        payload="${line#*\"}"; payload="${payload%%\"*}"
      elif [[ "$line" == *\'*\'* ]]; then
        payload="${line#*\'}"; payload="${payload%%\'*}"
      fi
      if [[ -n "$payload" ]]; then
        line="${payload#"${payload%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
      fi
    fi

    # Plain comments are ignored, but we keep scanning the header.
    [[ "$line" == \#* && "$line" != \#:* ]] && continue

    # First line that is neither a comment nor a tag ends the header.
    [[ "$line" != \#:* ]] && break

    key="${line#\#:}"; key="${key%%:*}"
    val="${line#\#:${key}:}"
    val="${val#"${val%%[![:space:]]*}"}"; val="${val%"${val##*[![:space:]]}"}"

    case "$key" in
      desc)    _q_desc+=("$val") ;;
      usage)   Q_P_USAGE="$val" ;;
      no-args) case "${(L)val}" in
                 1|true|yes|y|on) Q_P_NO_ARGS="true" ;;
                 *)               Q_P_NO_ARGS="false" ;;
               esac ;;
    esac
  done

  # zsh does NOT expand parameters inside (j.…) flags, so join by hand.
  out=""
  for part in "${_q_desc[@]}"; do
    [[ -z "$part" ]] && continue
    if [[ -z "$out" ]]; then out="$part"; else out+="${Q_DESC_JOIN}${part}"; fi
  done
  Q_P_DESC="$out"
}

Q_parse_metadata_from_file() {
  local path="$1"
  [[ -r "$path" ]] || return 1
  Q_parse_text "$(< "$path")"
  return 0
}

Q_parse_metadata_from_function() {
  local fn="$1"
  [[ -n "${functions[$fn]:-}" ]] || return 1
  # NOTE: unlike `typeset -f`, ${functions[name]} already OMITS the
  # "name () {" signature line — do not head-strip it or the first
  # metadata line (desc) gets thrown away.
  Q_parse_text "${functions[$fn]}"
  return 0
}

# Legacy stdin-compatible API (kept for tests / external use).
Q_parse_metadata_from_lines() {
  local _t; _t="$(cat)"
  Q_parse_text "$_t"
  print -r -- "desc=$Q_P_DESC"
  print -r -- "usage=$Q_P_USAGE"
  print -r -- "no_args=$Q_P_NO_ARGS"
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

  local sp fn

  # scripts first
  while IFS= read -r sp; do
    Q_parse_metadata_from_file "$sp" 2>/dev/null || continue
    Q_index_put "${sp:t}" "script" "$sp" "$Q_P_DESC" "$Q_P_USAGE" "$Q_P_NO_ARGS"
  done < <(Q_collect_script_paths)

  # functions override scripts (iterate the hash directly — no fork)
  for fn in ${(k)functions}; do
    [[ "$fn" == ${Q_PREFIX}* ]] || continue
    Q_parse_metadata_from_function "$fn" 2>/dev/null || continue
    Q_index_put "$fn" "function" "<function>" "$Q_P_DESC" "$Q_P_USAGE" "$Q_P_NO_ARGS"
  done

  return 0
}


Q_dump_index() {
  Q_build_index || return 1
  local name
  for name in ${(on)${(k)Q_IDX_source_type}}; do
    print -r -- "$name | ${Q_IDX_source_type[$name]} | no-args=${Q_IDX_no_args[$name]} | desc=${Q_IDX_desc[$name]} | usage=${Q_IDX_usage[$name]} | src=${Q_IDX_source_path[$name]}"
  done
}

# Reports entries with missing/incomplete metadata, plus cq_* files that are
# invisible to Q because they are not executable.
Q_doctor() {
  Q_build_index || return 1

  local name missing any=0
  local -a no_desc=() no_usage=() no_noargs=()

  for name in ${(on)${(k)Q_IDX_source_type}}; do
    [[ -n "${Q_IDX_desc[$name]}"    ]] || no_desc+=("$name")
    [[ -n "${Q_IDX_usage[$name]}"   ]] || no_usage+=("$name")
    [[ -n "${Q_IDX_no_args[$name]}" ]] || no_noargs+=("$name")
  done

  _q_doctor_group "missing #:desc:"    "${no_desc[@]}"
  _q_doctor_group "missing #:usage:"   "${no_usage[@]}"
  _q_doctor_group "missing #:no-args:" "${no_noargs[@]}"

  # cq_* files sitting in a scanned dir but not executable -> never indexed
  local -a dirs; dirs=(${(s/:/)PATH})
  [[ -n "$Q_EXTRA_DIRS" ]] && dirs+=(${(s/:/)Q_EXTRA_DIRS})
  local -a orphan=()
  local dir p base
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    for p in "$dir"/${Q_PREFIX}*(N); do
      [[ -f "$p" && ! -x "$p" ]] || continue
      orphan+=("$p")
    done
  done
  _q_doctor_group "not executable (invisible to Q):" "${orphan[@]}"

  print -r -- ""
  print -r -- "indexed entries: ${#Q_IDX_source_type}"
  if (( ${#no_desc} + ${#no_usage} + ${#no_noargs} == 0 && ${#orphan} == 0 )); then
    print -r -- "✅ all metadata complete"
  else
    print -r -- "⚠️  some entries need headers — see above"
  fi
}

_q_doctor_group() {
  local label="$1"; shift
  (( $# > 0 )) || return 0
  print -r -- "$label"
  local x
  for x in "$@"; do print -r -- "  - $x"; done
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

# Builds a temp DIR holding:
#   index.tsv  name \t type \t desc \t usage \t no_args \t source_path
#   f/<name>   dumped body, for function entries only (a /bin/sh preview cannot
#              see zsh functions, so they have to be materialised on disk)
# Scripts point straight at their real file — nothing is copied.
Q_make_preview_cache() {
  local dir; dir="$(mktemp -d -t qprev.XXXXXX)" || return 1
  local name src
  local -a fns; fns=()

  local n t
  for n in ${(on)${(k)Q_IDX_source_type}}; do
    t="${Q_IDX_source_type[$n]}"
    if [[ "$t" == "function" ]]; then fns+=("$n"); fi
  done

  if (( ${#fns} )); then
    mkdir -p "$dir/f" 2>/dev/null || true
    for name in "${fns[@]}"; do
      print -r -- "${functions[$name]}" >| "$dir/f/$name" 2>/dev/null || true
    done
  fi

  {
    for name in ${(on)${(k)Q_IDX_source_type}}; do
      if [[ "${Q_IDX_source_type[$name]}" == "function" ]]; then
        src="$dir/f/$name"
      else
        src="${Q_IDX_source_path[$name]}"
      fi
      print -r -- \
        "$name"$'\t'"${Q_IDX_source_type[$name]}"$'\t'"${Q_IDX_desc[$name]}"$'\t'"${Q_IDX_usage[$name]}"$'\t'"${Q_IDX_no_args[$name]}"$'\t'"$src"
    done
  } >| "$dir/index.tsv"

  print -r -- "$dir"
}

Q_run_fzf() {
  Q_has "$Q_FZF_CMD" || return 1

  local cachedir="" pscript=""
  local -a opts
  opts=(
    --ansi
    --delimiter $'\t'
    --with-nth 1,2
    --nth 1,2
    --layout reverse
    --border
  )

  # Preview is opt-in and costs temp files, so only build it when asked.
  case "${(L)Q_ENABLE_PREVIEW}" in
    1|true|yes|on)
      cachedir="$(Q_make_preview_cache)" || return 1
      pscript="$(mktemp -t q-preview-cmd.XXXXXX)" || { rm -rf -- "$cachedir"; return 1; }
      cat >| "$pscript" <<'SH'
#!/bin/sh
# $1 = cache dir, $2 = selected name, $3 = max source lines
dir="$1"; name="$2"; max="${3:-48}"

row=$(awk -F '\t' -v n="$name" '$1==n {print; exit}' "$dir/index.tsv")
[ -z "$row" ] && exit 0

type=$(printf '%s' "$row"    | cut -f2)
desc=$(printf '%s' "$row"    | cut -f3)
usg=$(printf '%s' "$row"    | cut -f4)
na=$(printf '%s' "$row"     | cut -f5)
src=$(printf '%s' "$row"    | cut -f6)

case "$na" in true) na=True ;; *) na=False ;; esac

printf '\033[1m%s\033[0m  \033[2m(%s, takes args: %s)\033[0m\n' "$name" "$type" "$na"
[ -n "$desc" ] || desc='(no #:desc:)'
[ -n "$usg" ]  || usg='(no #:usage:)'
printf '%s\n\033[2m%s\033[0m\n\n' "$desc" "$usg"

if [ -n "$src" ] && [ -r "$src" ]; then
  printf '\033[2m──── %s ────\033[0m\n' "$src"
  total=$(wc -l < "$src")
  sed -n "1,${max}p" "$src"
  if [ "$total" -gt "$max" ]; then
    printf '\033[2m… %s more lines\033[0m\n' "$(( total - max ))"
  fi
else
  printf '\033[2m(source not readable)\033[0m\n'
fi
SH
      chmod +x "$pscript" 2>/dev/null || true
      opts+=( --preview-window right:62%:wrap --preview "$pscript $cachedir {1} ${Q_PREVIEW_LINES:-48}" )
      ;;
  esac

  # User extras go LAST so they override the built-ins (fzf honours the later flag).
  [[ -n "$Q_FZF_OPTS" ]] && opts+=(${(z)Q_FZF_OPTS})

  local chosen rc
  chosen="$(
    Q_build_fzf_lines | env -i PATH="$PATH" HOME="$HOME" \
      TERM="${TERM:-xterm-256color}" LANG="${LANG:-C.UTF-8}" \
      "$Q_FZF_CMD" "${opts[@]}"
  )"
  rc=$?
  [[ -n "$cachedir" ]] && rm -rf -- "$cachedir" 2>/dev/null || true
  [[ -n "$pscript"  ]] && rm -f  -- "$pscript"  2>/dev/null || true
  (( rc == 0 )) || return $rc
  print -r -- "$chosen"
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
  Q_parse_metadata_from_file "$s1" || { Q_err "parse failed"; return 1; }
  desc="$Q_P_DESC"; usage="$Q_P_USAGE"; no_args="$Q_P_NO_ARGS"

  Q_assert_eq "$desc" "Script one" "parse desc from file" || fail=1
  Q_assert_eq "$usage" "cq_script1 <x>" "parse usage from file" || fail=1
  Q_assert_eq "$no_args" "false" "parse no-args from file" || fail=1

  # absent tags must stay empty so --doctor can tell "false" from "not declared"
  local s2="$tmp/cq_script2"
  cat > "$s2" <<'EOF'
#!/usr/bin/env bash
#:desc: Only a description

echo "hi"
EOF
  chmod +x "$s2"
  Q_parse_metadata_from_file "$s2" || { Q_err "parse failed"; return 1; }
  Q_assert_eq "$Q_P_USAGE"   ""                  "absent usage stays empty" || fail=1
  Q_assert_eq "$Q_P_NO_ARGS" ""                  "absent no-args stays empty" || fail=1
  Q_assert_eq "$Q_P_DESC"    "Only a description" "desc still parsed"       || fail=1

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
      --doctor) mode="doctor"; shift ;;
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
    doctor)
      Q_doctor
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
      --help|-h|--dump-index|--doctor|--dump-fzf-input|--collect-functions|--collect-scripts|--parse-file|--parse-function|--select|--test|--) 
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

