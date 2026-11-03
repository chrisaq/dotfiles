#!/bin/bash

umask 077

status=0
tempfile=

error() {
    printf 'crypt-sync: %s\n' "$*" >&2
}

cleanup() {
    if [ -n "$tempfile" ]; then
        if ! rm -f -- "$tempfile"; then
            error "Could not remove temporary file: $tempfile"
            return 1
        fi
        tempfile=
    fi
}

trap 'cleanup || exit 1' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

# Keep the lock file: unlinking it would let concurrent runs lock different inodes.
lock_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/crypt-sync"
if ! mkdir -p -- "$lock_dir"; then
    error "Could not create lock directory: $lock_dir"
    exit 1
fi
if ! exec {lock_fd}>> "$lock_dir/run.lock"; then
    error "Could not open lock file: $lock_dir/run.lock"
    exit 1
fi
if ! flock -n "$lock_fd"; then
    error 'Could not acquire lock; another crypt-sync run may be active.'
    exit 1
fi

regular_or_missing() {
    local path=$1
    if [[ -L $path || ( -e $path && ! -f $path ) ]]; then
        error "Refusing symlink or nonregular file: $path"
        return 1
    fi
}

transfer() {
    local direction=$1 source=$2 destination=$3 directory
    local -a gpg_options

    directory=$(dirname -- "$destination") || return 1
    if ! mkdir -p -- "$directory"; then
        error "Could not create destination directory: $directory"
        return 1
    fi
    if ! tempfile=$(mktemp -- "$directory/.crypt-sync.XXXXXXXXXX"); then
        error "Could not create temporary file in: $directory"
        return 1
    fi

    if [ "$direction" = decrypt ]; then
        printf 'Decrypting from vault to config file: %s\n' "$destination"
        gpg_options=(--decrypt)
    else
        printf 'Encrypting local file to vault: %s\n' "$destination"
        gpg_options=(--encrypt --armor --recipient 0xAEE3FD309AFCC09E)
    fi

    if ! gpg --yes --output "$tempfile" "${gpg_options[@]}" "$source"; then
        error "GPG failed to $direction: $source"
        return 1
    fi
    if ! chmod 600 -- "$tempfile"; then
        error "Could not set output permissions: $destination"
        return 1
    fi
    if ! touch -r "$source" -- "$tempfile"; then
        error "Could not copy source timestamp: $source"
        return 1
    fi
    regular_or_missing "$destination" || return 1
    if ! mv -fT -- "$tempfile" "$destination"; then
        error "Could not replace destination: $destination"
        return 1
    fi
    tempfile=
}

process_list() {
    local line cryptfile locfile

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
        esac
        printf '%s\n' "$line"
        cryptfile=${line%%:*}
        locfile=${line#*:}
        if [ "$cryptfile" = "$line" ] || [ -z "$cryptfile" ] || [ -z "$locfile" ]; then
            error "Skipping malformed line: $line"
            status=1
            continue
        fi
        cryptfile="${PASSWORD_STORE_DIR}/ConfigFiles/${cryptfile}"
        locfile="${HOME}/${locfile}"

        if ! regular_or_missing "$cryptfile" || ! regular_or_missing "$locfile"; then
            status=1
            continue
        fi
        if [ ! -e "$cryptfile" ] && [ ! -e "$locfile" ]; then
            printf 'Missing both files, skipping\n'
            continue
        fi

        if [ ! -e "$locfile" ] || [ "$locfile" -ot "$cryptfile" ]; then
            transfer decrypt "$cryptfile" "$locfile" || status=1
        elif [ ! -e "$cryptfile" ] || [ "$cryptfile" -ot "$locfile" ]; then
            transfer encrypt "$locfile" "$cryptfile" || status=1
        else
            printf 'Same date, leaving alone\n'
        fi
        cleanup || exit 1
    done
}

for syncfile in "${XDG_BIN_HOME}"/crypt-sync/crypt-sync-list*.txt; do
    [ -e "$syncfile" ] || continue
    if [ ! -f "$syncfile" ]; then
        error "Not a regular list file: $syncfile"
        status=1
        continue
    fi
    if ! process_list < "$syncfile"; then
        error "Could not process list: $syncfile"
        status=1
    fi
done

exit "$status"
