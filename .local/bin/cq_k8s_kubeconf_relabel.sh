#!/bin/bash
#:usage: cq_k8s_kubeconf_relabel.sh <label>
#:no-args: false
#:desc: Relabel default k3s kubeconfig context/user/cluster.

# Relabel/rename k8s "default" context, user, and cluster to something
# that you can actually identify.
# $1 is a label that is prefixed to the type.

# Ensure a variable is passed as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <variable>"
  exit 1
fi

# Define the variable
VAR=$1

# Define the path to the k3s.yaml file
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"

# Read the original file content with sudo
ORIGINAL_CONTENT=$(sudo cat "$KUBECONFIG_PATH")

# Modify the content using sed and store it in a variable
MODIFIED_CONTENT=$(echo "$ORIGINAL_CONTENT" | sed -e "s/name: default/name: ${VAR}-context/g" \
                                                  -e "s/user: default/user: ${VAR}-user/g" \
                                                  -e "s/cluster: default/cluster: ${VAR}-cluster/g" \
                                                  -e "s/current-context: default/current-context: ${VAR}-context/g")

# Output the modified content to stdout
echo "$MODIFIED_CONTENT"
