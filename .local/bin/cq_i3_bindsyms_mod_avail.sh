#!/bin/bash
#:usage: cq_i3_bindsyms_mod_avail.sh
#:no-args: true
#:desc: List unused $mod keybindings in the i3 config.


cq_config_file() {  # prints config file path; empty = use defaults
  local app="i3-bindsyms-mod-avail" ext="sh" base f
  if [[ -n "${CQ_I3_BINDSYMS_MOD_AVAIL_CONFIG:-}" ]]; then
    f="$CQ_I3_BINDSYMS_MOD_AVAIL_CONFIG"
    [[ -d "$f" || ( ! "$f" == *.* && ! -f "$f" ) ]] && f="$f/config.$ext"
    [[ -f "$f" ]] || { echo "cq_i3_bindsyms_mod_avail: config not found: $f" >&2; return 1; }
    printf '%s\n' "$f"; return 0
  fi
  base="${CQ_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/cq}"
  for f in "$base/$app/config.$ext" "$base/$app.$ext"; do
    [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }
  done
  return 0  # empty: defaults
}
if ! cq_cfg=$(cq_config_file); then exit 1; fi
if [[ -n "$cq_cfg" ]]; then
  # shellcheck source=/dev/null
  source "$cq_cfg"
fi

# Path to your i3 config file
I3_CONFIG="${I3_CONFIG:-$HOME/.config/i3/config}"

# Extract all bindsym lines that include $mod
used_binds=$(grep "bindsym.*\$mod" "$I3_CONFIG" | awk '{print $2}')

# List of keys to check for binding
KEYS=("a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" 
      "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "Return" "space" "Tab" "Escape" "BackSpace" "Delete" "Up" "Down" "Left" "Right")

# Generate possible $mod+key combinations and check if they are used
available_binds=()
for key in "${KEYS[@]}"; do
    combination="\$mod+$key"
    if ! echo "$used_binds" | grep -qw "$combination"; then
        available_binds+=("$combination")
    fi
done

# Output available $mod+key bindings
if [ ${#available_binds[@]} -eq 0 ]; then
    echo "No available keybindings with \$mod."
else
    echo "Available keybindings with \$mod:"
    for bind in "${available_binds[@]}"; do
        echo "$bind"
    done
fi
