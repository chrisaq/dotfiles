#!/bin/bash
#:usage: cq_k8s_kubeconf_relabel.sh <label>
#:no-args: false
#:desc: Relabel default k3s kubeconfig context/user/cluster.

# Relabel/rename k8s "default" context, user, and cluster to something
# that you can actually identify.
# $1 is a label that is prefixed to the type.

cq_config_file() {  # prints config file path; empty = use defaults
  local app="k8s-kubeconf-relabel" ext="sh" base f
  if [[ -n "${CQ_K8S_KUBECONF_RELABEL_CONFIG:-}" ]]; then
    f="$CQ_K8S_KUBECONF_RELABEL_CONFIG"
    [[ -d "$f" || ( ! "$f" == *.* && ! -f "$f" ) ]] && f="$f/config.$ext"
    [[ -f "$f" ]] || { echo "cq_k8s_kubeconf_relabel: config not found: $f" >&2; return 1; }
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

# Ensure a variable is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <variable>"
  exit 1
fi

# Define the variable
VAR=$1

# Define the path to the k3s.yaml file
KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/rancher/k3s/k3s.yaml}"

# Read the original file content with sudo
ORIGINAL_CONTENT=$(sudo cat "$KUBECONFIG_PATH")

# Modify the content using sed and store it in a variable
MODIFIED_CONTENT=$(echo "$ORIGINAL_CONTENT" | sed -e "s/name: default/name: ${VAR}-context/g" \
                                                  -e "s/user: default/user: ${VAR}-user/g" \
                                                  -e "s/cluster: default/cluster: ${VAR}-cluster/g" \
                                                  -e "s/current-context: default/current-context: ${VAR}-context/g")

# Output the modified content to stdout
echo "$MODIFIED_CONTENT"
